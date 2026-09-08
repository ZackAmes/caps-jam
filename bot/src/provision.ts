import { Account, CallData, RpcProvider, constants, ec, hash, uint256 } from 'starknet';
import { existsSync, mkdirSync, readFileSync, writeFileSync, chmodSync } from 'node:fs';
import { resolve } from 'node:path';

const STRK = '0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d';
interface SavedAccount { address: string; publicKey: string; privateKey: string; classHash: string }

async function provision() {
  const profilePath = process.argv[2];
  const amount = process.argv[3] ?? '5';
  if (!profilePath || !/^\d+$/.test(amount) || BigInt(amount) > 20n) throw new Error('Usage: bun src/provision.ts <Sepolia profile.toml> <target balance in STRK, max 20>');
  const profile = Bun.TOML.parse(readFileSync(profilePath, 'utf8')) as { env: { rpc_url: string; account_address: string; private_key: string } };
  const provider = new RpcProvider({ nodeUrl: profile.env.rpc_url });
  if (await provider.getChainId() !== constants.StarknetChainId.SN_SEPOLIA) throw new Error('Provisioning is restricted to Sepolia');
  const stateDir = resolve(import.meta.dir, '../state');
  mkdirSync(stateDir, { recursive: true, mode: 0o700 });
  const accountPath = resolve(stateDir, 'account.json');
  let saved: SavedAccount;
  if (existsSync(accountPath)) saved = JSON.parse(readFileSync(accountPath, 'utf8'));
  else {
    const classHash = await provider.getClassHashAt(profile.env.account_address);
    const contract = await provider.getClassAt(profile.env.account_address);
    const abi = typeof contract.abi === 'string' ? JSON.parse(contract.abi) : contract.abi;
    const constructor = abi.find((entry: { type: string }) => entry.type === 'constructor');
    if (constructor?.inputs.length !== 1 || constructor.inputs[0].name !== 'public_key') throw new Error('Source account must use a single-public-key constructor');
    const privateKey = '0x' + Buffer.from(ec.starkCurve.utils.randomPrivateKey()).toString('hex');
    const publicKey = ec.starkCurve.getStarkKey(privateKey);
    const address = hash.calculateContractAddressFromHash(publicKey, classHash, [publicKey], 0);
    saved = { address, publicKey, privateKey, classHash };
    writeFileSync(accountPath, JSON.stringify(saved, null, 2), { mode: 0o600, flag: 'wx' });
  }
  if (BigInt(saved.address) === BigInt(profile.env.account_address)) throw new Error('Bot must have a separate account');
  const balance = await provider.callContract({ contractAddress: STRK, entrypoint: 'balance_of', calldata: [saved.address] });
  const current = BigInt(balance[0]) + (BigInt(balance[1]) << 128n);
  const target = BigInt(amount) * 10n ** 18n;
  if (current < target) {
    const source = new Account({ provider, address: profile.env.account_address, signer: profile.env.private_key });
    const tx = await source.execute({ contractAddress: STRK, entrypoint: 'transfer', calldata: CallData.compile([saved.address, uint256.bnToUint256(target - current)]) }, { tip: 0 });
    console.log('funding_transaction', tx.transaction_hash);
    const receipt = await provider.waitForTransaction(tx.transaction_hash);
    if (!receipt.isSuccess()) throw new Error('Funding transaction failed');
  }
  let deployed = false;
  try {
    const currentClass = await provider.getClassHashAt(saved.address);
    if (BigInt(currentClass) !== BigInt(saved.classHash)) throw new Error('Account class mismatch');
    deployed = true;
  } catch (error) {
    if (!(typeof error === 'object' && error && 'code' in error && error.code === 20)) throw error;
  }
  if (!deployed) {
    const account = new Account({ provider, address: saved.address, signer: saved.privateKey });
    const tx = await account.deployAccount({ classHash: saved.classHash, constructorCalldata: [saved.publicKey], addressSalt: saved.publicKey }, { tip: 0 });
    console.log('account_deployment_transaction', tx.transaction_hash);
    const receipt = await provider.waitForTransaction(tx.transaction_hash);
    if (!receipt.isSuccess()) throw new Error('Account deployment failed');
  }
  const envPath = resolve(import.meta.dir, '../.env');
  writeFileSync(envPath, `BOT_RPC_URL=${profile.env.rpc_url}\nBOT_ADDRESS=${saved.address}\nBOT_PRIVATE_KEY=${saved.privateKey}\nBOT_POLL_MS=15000\n`, { mode: 0o600 });
  chmodSync(envPath, 0o600);
  writeFileSync(resolve(import.meta.dir, '../account.public.json'), JSON.stringify({ address: saved.address, classHash: saved.classHash, network: 'SN_SEPOLIA' }, null, 2) + '\n');
  console.log('bot_address', saved.address);
}
provision().catch(() => { console.error('Account provisioning failed; inspect RPC/account configuration and retry. Saved keys, if generated, are retained in bot/state/account.json.'); process.exitCode = 1; });

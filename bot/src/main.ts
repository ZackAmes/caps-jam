import { Account, RpcProvider, constants } from 'starknet';
import { loadConfig } from './config';
import { CapsV5Adapter } from './game/v5';
import { greedyStrategy } from './strategies/greedy';
import { FileStore } from './store';
import { BotWorker, message } from './worker';
import type { Logger } from './ports';

async function main() {
  const config = loadConfig();
  const log: Logger = (event, fields = {}) => {
    const safe = JSON.stringify({ time: new Date().toISOString(), event, ...fields })
      .replaceAll(config.privateKey, '[redacted]').replaceAll(config.rpcUrl, '[rpc]');
    console.log(safe);
  };
  const provider = new RpcProvider({ nodeUrl: config.rpcUrl });
  const chainId = await provider.getChainId();
  if (chainId !== constants.StarknetChainId.SN_SEPOLIA) throw new Error('This bot is configured for Sepolia only');
  const account = new Account({ provider, address: config.address, signer: config.privateKey });
  const adapter = new CapsV5Adapter(provider, account, config.actionsAddress);
  await adapter.checkCompatibility();
  const identity = `${chainId}:${BigInt(config.actionsAddress)}:${BigInt(config.address)}:rules5`;
  const store = new FileStore(config.statePath);
  const unlock = store.lock();
  const abort = new AbortController();
  process.once('SIGTERM', () => abort.abort());
  process.once('SIGINT', () => abort.abort());
  try {
    const worker = new BotWorker(adapter, greedyStrategy, config.address, store.load(identity), store, log);
    log('started', { address: config.address, actionsAddress: config.actionsAddress, strategy: greedyStrategy.name });
    let failures = 0;
    do {
      try { await worker.tick(); failures = 0; }
      catch (error) { failures++; log('poll_retry', { error: message(error), failures }); }
      if (process.argv.includes('--once') || abort.signal.aborted) break;
      const delay = Math.min(config.pollMs * 2 ** Math.min(failures, 4), 120000);
      await new Promise<void>(resolve => {
        const stop = () => { clearTimeout(timer); resolve(); };
        const timer = setTimeout(() => { abort.signal.removeEventListener('abort', stop); resolve(); }, delay);
        abort.signal.addEventListener('abort', stop, { once: true });
      });
    } while (!abort.signal.aborted);
  } finally { unlock(); }
}

main().catch(error => {
  console.error('Bot startup failed:', message(error).replaceAll(process.env.BOT_PRIVATE_KEY || '[unset]', '[redacted]'));
  process.exitCode = 1;
});

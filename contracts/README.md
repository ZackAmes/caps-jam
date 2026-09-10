# CAPS contracts

Dojo 1.8 / Cairo 2.13.1 contracts for the CAPS tactical board game.

See [current rules](../docs/GAME_DESIGN.md) for gameplay and balance values.

## Validate

From this directory, using Scarb 2.13.1:

```sh
scarb build
scarb test
```

The tests deploy a Dojo test world and exercise the actual actions contract and reference set. They do not submit network transactions or spend Sepolia funds. `test_game.ts` is a separate legacy manual network smoke script.

## Deploying this rules version

Rules v6 upgrades the existing September 8 world in place. Preserve the Sepolia profile
seed and world address. `GameClock` is a new, separate model; existing `Game` storage,
rosters and board layouts remain compatible. Migrate the model and actions contract,
then copy `manifest_sepolia.json` to `client/src/lib/dojo/manifest.json`.

The client and bot require rules version 6. Stop the bot during migration, preserve its
checkpoint when changing the version suffix, and restart it after verifying the new ABI.
Set Zero remains registered as set 0 and does not need replacing for this upgrade.

The hardcoded Sepolia test account is intentionally retained for the current development workflow.

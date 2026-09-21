# 1 Joker

A [Steamodded](https://github.com/Steamodded/smods) mod for Balatro that spawns a Joker of your
choosing every ante, optionally with a forced edition and a hand-picked set of starting Jokers.

## Install

1. Install Steamodded (1.0.0 or newer).
2. Copy this folder into `%APPDATA%/Balatro/Mods/1-joker` (Windows) or
   `~/Library/Application Support/Balatro/Mods/1-joker` (macOS).
3. Launch the game, open `MODS` → `1 Joker` → `Config`.

## Config

| Option | Effect |
| --- | --- |
| Spawn every ante | Master switch for the ante spawns. Starting Jokers still apply when off. |
| Joker | The Joker that gets spawned. `None` disables the spawn. |
| Edition | `None`, a forced edition, or `Random` (Foil / Holographic / Polychrome, rolled per card). |
| Copies | 1–5 copies per spawn. |
| Cadence | Every ante, or every N antes, anchored on ante 1. |
| Also spawn on ante 1 | Whether the run starts with the first spawn already in hand. |
| Start 1–3 | Extra Jokers (each with its own edition) added at run start — your synergy picks. |

Settings are stored in `config.lua`, which you can also edit directly if clicking through the
whole Joker list is tedious. Unknown or uninstalled Joker keys fall back to sensible defaults on
load, so pulling a mod out of your Mods folder will not break an existing config.

Spawns ignore Joker slot limits, exactly like a Negative Joker would — if you are full, the card
is still added.

## Development

Game-independent logic lives in `src/` and is covered by [busted](https://lunarmodules.github.io/busted/) specs:

```sh
luarocks install busted   # or: apt-get install lua-busted
busted spec/
```

`spec/mod_config_spec.lua` keeps the shipped `config.lua` in step with `Config.defaults()`.

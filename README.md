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
| Joker | The Joker that gets spawned, picked from a card grid. `X` clears it, which disables the spawn. |
| Edition | `None`, a forced edition, or `Random` (Foil / Holographic / Polychrome, rolled per card). |
| Copies | 1–5 copies per spawn. |
| Cadence | Every ante, or every N antes, anchored on ante 1. |
| Spawn on ante 1 | Whether the run starts with the first spawn already in hand. |
| Slots = spawns | Caps the run's Joker slots at the number of slot-consuming Jokers this mod has spawned, so the only Jokers you can hold are the ones it gave you. |
| Start 1–3 | Extra Jokers (each with its own edition) added at run start — your synergy picks. |

Joker buttons open the card collection grid: click a Joker to pick it, or page through with the
shoulder buttons on a controller / Steam Deck.

Settings are stored in `config.lua`, which you can also edit directly. Unknown or uninstalled Joker keys fall back to sensible defaults on
load, so pulling a mod out of your Mods folder will not break an existing config.

Spawns ignore the current Joker slot limit — if you are full, the card is still added.

With `Slots = spawns` on, the slot limit is rewritten every time the mod spawns something: one slot
after the ante 1 spawn, two after ante 2, and so on, plus one per starting Joker. Slots bought from
vouchers get clawed back on the next spawn. Turn it off to play with vanilla slots. The count lives
on the run (`G.GAME.onejoker_spawned`), so it survives saves.

Negative Jokers are left out of the cap and behave as they normally would: they do not raise the
spawn count, and every Negative Joker you hold — spawned or bought — adds its slot back on top of
the cap.

## Development

Game-independent logic lives in `src/` and is covered by [busted](https://lunarmodules.github.io/busted/) specs:

```sh
luarocks install busted   # or: apt-get install lua-busted
busted spec/
```

`spec/mod_config_spec.lua` keeps the shipped `config.lua` in step with `Config.defaults()`.

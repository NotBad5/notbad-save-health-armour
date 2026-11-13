# notbad-save-health-armour

Saves a player's health and armour when they leave the server and gives them back when they return. Works standalone or with ESX, QBCore and Qbox, where values are saved per character.

## Features
- **No database needed**: values are stored in FiveM's built-in storage by default. MySQL through oxmysql is optional
- **Framework detected automatically**: ESX, Qbox, QBCore or standalone
- **Per character** with multicharacter scripts, including character switching without reconnecting
- **Read by the server**: clients never report their own health, and saved values are only handed out once per session
- **Survives model changes**: clothing and character scripts reset health to full, the saved values are put back
- **Dead players**: choose whether someone who left while dead returns dead or is left to your ambulance job
- **Combat log reports**: optional Discord message when a player leaves dead or badly hurt
- **Crash safe**: values are also written periodically and when the resource stops

## Install
1. Put the `notbad-save-health-armour` folder in your `resources` directory.
2. Add `ensure notbad-save-health-armour` to `server.cfg`. With a framework, place it after the framework.
3. That is it. Check `config.lua` if you want to change something.

Requires OneSync, which is on by default on current servers.

## Config
| Option | What it does |
|---|---|
| `Config.Framework` | `'auto'`, or force `'esx'`, `'qbx'`, `'qb'`, `'standalone'` |
| `Config.Storage` | `'kvp'` (no database) or `'oxmysql'` |
| `Config.SaveHealth`, `Config.SaveArmour` | Turn either one off |
| `Config.DeadPlayers` | `'skip'` leaves a dead player's health alone, `'kill'` brings them back dead |
| `Config.CheckInterval` | Seconds between health checks on the server |
| `Config.WriteInterval` | Seconds between writes to storage |
| `Config.ReapplySeconds` | How long saved values are put back after a model change |
| `Config.Debug` | Print saves and loads to the server console |

## Combat log reports
Set a Discord webhook in `server/config.lua` and the server posts a message when a player disconnects while dead or below a health threshold. The message shows the player, health, armour, identifier, the disconnect reason and their position.

| Option | What it does |
|---|---|
| `webhook` | Discord webhook URL. Empty turns the feature off |
| `logDead` | Report players who leave while dead |
| `lowHealth` | Report players who leave alive below this health, in percent. `0` turns it off |
| `logCharacterSwitch` | Also report switching character in that state |
| `botName` | Name the messages are posted under |

The webhook lives in `server/config.lua` on purpose: that file is never sent to players. Do not move it to `config.lua`.

A report is not proof. A crash or a lost connection looks the same as someone pulling the plug, so check the disconnect reason before you act on it.

## Upgrading from 1.0
- `mysql-async` is no longer used. Either keep the default (`'kvp'`, no database) or set `Config.Storage = 'oxmysql'`.
- With `'oxmysql'` the old `notbad_health_armour` table and its rows keep working. The table is created automatically, so `sql.sql` is gone.
- Switching to `'kvp'` starts with empty storage: players get their saved values again from their next disconnect.
- The config options `Config.Standalone`, `Config.ESX` and `Config.QBCORE` are replaced by `Config.Framework`.

## License
GPL-3.0, see `LICENSE`.

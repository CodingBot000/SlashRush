# Slash Rush

Godot 4.x / GDScript prototype for a mobile landscape 2D action runner.

## Run

Open this folder in Godot and run `res://scenes/Main.tscn`.

CLI smoke check:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/dev/SmokeTest.gd
```

## Controls

- Tap / Space / left mouse: basic slash, start, retry
- Double tap / Space twice / left mouse twice: fast enemy and boss combo
- Hold tap / hold Space / hold left mouse: armor enemy and boss guard
- R: debug restart

Good items should be collected by not slashing. Slashing them breaks them and gives no reward.

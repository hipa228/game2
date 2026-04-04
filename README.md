# 3D Horror Game - Godot Template

A 3D horror game template for Android built with Godot Engine (GDScript).

## Features

- First-person player controller with mouse look
- Basic enemy AI (patrolling and chase behavior)
- Dark atmospheric environment with lighting
- Interactive doors and objects
- Sound system for footsteps and ambient horror sounds
- Android touch controls support
- Export-ready for Android

## Requirements

- Godot Engine 4.3 or later
- Android SDK (for Android export)

## Project Structure

```
scenes/              # Godot scene files
  - player/          # Player character and camera
  - enemies/         # Enemy characters and AI
  - environment/     # Level geometry and props
  - ui/              # Menus and HUD
scripts/             # GDScript files
  - player/          # Player movement and interaction
  - enemies/         # Enemy behavior
  - game/            # Game state management
assets/              # 3D models, textures, sounds
  - models/          # GLTF or Godot scene files
  - textures/        # Image textures
  - sounds/          # Audio files
export_presets.cfg   # Export configurations
project.godot        # Godot project settings
```

## How to Run

1. Open Godot Engine
2. Click "Import" and select this project folder
3. Click "Run" to play in the editor
4. For Android: Configure export presets and export APK

## Controls

- **WASD/Arrow Keys**: Move player
- **Mouse**: Look around
- **E**: Interact with objects
- **Space**: Jump
- **Shift**: Sprint
- **Esc**: Pause menu

## Android Touch Controls

- Left virtual joystick: Movement
- Right touch area: Look around
- On-screen buttons: Interact, jump, sprint

## Getting Started

1. Open `scenes/main/main.tscn` as the main scene
2. Modify player settings in `scripts/player/player_controller.gd`
3. Add your own 3D models to `assets/models/`
4. Configure Android export in Project Settings > Export

## License

MIT
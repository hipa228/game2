# Horror Game Android Template

A simple horror-themed 2D game for Android built with Kotlin and Canvas.

## Features

- Touch-based movement control
- Enemy AI chasing player
- Collision detection
- Game loop with 60 FPS target
- Dark theme

## How to Build

1. Open project in Android Studio or use command line:
```
./gradlew assembleDebug
```

2. Install on device/emulator:
```
./gradlew installDebug
```

## Project Structure

- `app/src/main/kotlin/com/example/horrorgame/` - Game source code
  - `MainActivity.kt` - Activity entry point
  - `GameView.kt` - Custom SurfaceView with game loop
- `app/src/main/res/` - Resources (layouts, strings, colors)
- `app/build.gradle` - Module build configuration

## Gameplay

- Touch anywhere on screen to move the red circle (player).
- Green circles (enemies) will chase the player.
- Avoid touching enemies.
- Game ends when collision occurs.

## License

MIT
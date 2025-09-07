# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a 2D billiards game built with Godot 4.4. The game features:
- Player vs Player (PvP) and Player vs CPU (PvC) game modes
- Physics-based ball movement and collision system
- Audio system with music and sound effects
- Dynamic UI with power indicators and scoring
- CPU AI opponent with realistic aiming and shooting

## Commands

### Running the Game
- Open the project in Godot 4.4 using: `d:\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64.exe`
- The main scene is automatically loaded from `res://scenes/game.tscn` (UID: 716cygcnsjaf)
- Use F5 to run the project from within Godot

### Development
- No package manager or build system - this is a pure Godot project
- Use Godot's built-in editor for scene editing and script debugging
- VSCode integration is configured via `.vscode/settings.json`

## Architecture

### Core Game Structure
The game follows a node-based architecture typical of Godot projects:

```
Game (main scene) - Node2D
├── Table - handles physics boundaries and pockets
├── Balls (container) - holds all ball instances
├── CueStick - manages aiming and shooting mechanics
└── UI (CanvasLayer) - handles all user interface elements
```

### Key Script Files

**game.gd** (main controller): 
- Game state management (MENU, PLAYING, GAME_OVER)
- Game modes (PVP, PVC) and turn switching
- Win/loss condition system with configurable rules
- Audio system with separate music and SFX buses
- CPU AI player logic
- Ball spawn and rack setup

**scripts/table.gd**:
- Manages table physics (rails, pockets)
- Emits ball_pocketed signals when balls enter pockets
- Provides spawn positions for cue ball and rack

**scripts/cue_stick.gd**:
- Mouse-based aiming system with power control
- CPU shot animation and "thinking" behavior
- Shot power calculation based on distance from ball

**scripts/ui.gd**:
- Dynamic UI creation for menus and overlays
- Power indicator with color-coded bars
- Score tracking and player turn management
- Settings menu with volume controls

**scripts/ball.gd**:
- Physics-based ball movement with rotation animation
- Velocity-based visual effects (scaling, rotation speed)
- Support for both smooth rotation and frame-based animation

### Game Systems

**Physics System**:
- Uses Godot's RigidBody2D for realistic ball physics
- All balls have collision_layer = 1 and collision_mask = 1
- Table rails use StaticBody2D with configurable bounce physics
- Ball monitoring system prevents balls from escaping table bounds

**Audio System**:
- Three audio buses: Master, Music, SFX
- Dynamic sound selection based on shot power
- Background music switching between menu and game states
- Audio files located in `res://assets/audio/`

**Win/Loss Conditions**:
- Modular condition system using Callable arrays
- Current rules: 8+ balls pocketed wins, 3 scratches loses, early 8-ball pocketing loses
- Early 8-ball rule: Pocketing the 8-ball before clearing all other balls results in immediate loss
- Easily extensible for different game rule sets

**CPU AI**:
- Finds closest target ball for simple strategy
- Adds randomness to aim and power for realistic imperfection
- Animated "thinking" behavior with slight aim adjustments
- Uses coroutines for smooth shot timing

### Scene Structure
- Individual ball scenes (ball_1.tscn through ball_15.tscn, cue_ball.tscn)
- Main game scene (game.tscn) with all systems integrated
- UI elements created dynamically in code rather than scene files

### Asset Organization
- `assets/audio/` - Music and sound effect files (MP3 format)
- `assets/Fonts/` - Custom pixel fonts for UI
- `scenes/` - All .tscn scene files
- `scripts/` - All .gd script files

## Development Notes

### Physics Configuration
- Ball radius: 15.0 pixels
- Max shot power: 2500.0
- Ball damping: linear_damp = 1.0, angular_damp = 1.0
- Table boundaries approximately: Rect2(200, 100, 1400, 800)

### Audio Configuration
- Music volume range: -52db to -12db (mapped to 0-40 for UI)
- SFX volume range: -40db to 0db
- Break sounds triggered at 50% power threshold

### Game Balance
- CPU power range: 60-85% of max power
- CPU aim variation: ±0.2 radians for imperfection
- Turn switching after 3-second ball settling period
- Ball stationary threshold: velocity < 5.0 units
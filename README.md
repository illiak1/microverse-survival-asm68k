# Microverse Survival text-based game in Assembly 68k

## Credits

**Developed as part of the Assembly 68k Project**  
**Author**: Illia Karban

**Date**: 06.03.2026  

## Project Overview

Microverse Survival is a text-based survival game built for the EASy68K simulator. Players must survive in a harsh microverse environment for 15 days (Story Mode) or indefinitely (Endless Mode). The game features resource management, dynamic random events, and interactive gameplay.

## Features

### Two Game Modes:
- **Story Mode**: Survive 15 days to win.
- **Endless Mode**: Survive as long as possible and try to beat your high score.

### Resource Management:
- Track **Health**, **Food**, and **Energy**.
- Actions consume or restore resources.

### Daily Actions:
- **Rest**: Restore energy but consume food.
- **Explore**: Gain food but lose energy.
- **Hunt**: Gain more food at the cost of higher energy.

### Dynamic Random Events:
- **Drought**, **base attacks**, **rare resources**, **rare healing**, **screen glitch events**.

### Game Over / Win Conditions:
- Health reaches 0 → **Game Over**.
- **Story Mode**: Survive 15 days → **Win**.

### High Score Tracking:
- **Endless Mode** records and displays the highest days survived.

### Input Validation:
- Only valid choices accepted for mode selection and daily actions.
- Prompts user again on invalid input.

## How to Play

1. **Start the game** in EASy68K by loading the project and running it.
2. **Read the introduction** and press any key to continue.
3. **Choose a game mode**:
    - `0 = Story Mode`
    - `1 = Endless Mode`
4. **Each day**, choose one of three actions:
    - `1 = Rest`
    - `2 = Explore`
    - `3 = Hunt`
5. **Manage your resources carefully**:
    - Low food → Health decreases.
    - Low energy → Health decreases.
6. Survive as many days as possible! After the game ends, choose whether to play again.

## Controls

- **Keyboard Input**:
    - Number keys (0–3) for choices.
    - `Y/N` for restart prompt.
    - Any other key → ignored or reprompted.

## Flowchart

The diagram below illustrates the main game flow for **Microverse Survival**. It shows the sequence from game initialization through the main gameplay loop, handling player inputs, random events, resource updates, and game over or victory conditions.

[![Flowchart - Microverse Survival](Flowchart%20-%20Microverse%20Survival.png)](https://github.com/illiak1/microverse-survival-asm68k/blob/main/Flowchart%20%20-%20Microverse%20Survival.png)
*Example of a game flowchart.*

## Gameplay Video

A gameplay video demonstrating the full game experience, including mode selection, daily actions, random events, and end conditions, is available to showcase the mechanics and user interaction.

[![Gameplay Video - Microverse Survival](Gameplay%20Video%20-%20Microverse%20Survival.mp4)](https://github.com/illiak1/microverse-survival-asm68k/blob/main/Gameplay%20Video%20-%20Microverse%20Survival.mp4)
*Click here to watch the gameplay video.*  


## Files Included

- `Microverse Survival.X68` — Main program source code.
- `README.md` — Project description, instructions, and features.
- `Gameplay Video - Microverse Survival.mp4` — Gameplay video.
- `Flowchart - Microverse Survival.png` — Flowchart image.

---

### Example of How to Run the Code:
```bash
# Run the game in the EASy68K simulator
load Microverse_Survival.X68

run




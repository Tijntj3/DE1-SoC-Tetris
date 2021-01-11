# DE1-SoC Tetris

Repository that contains the sources for the DE1-SoC Tetris project. It is the final assignment of the Digital Systems Design course. The main goal of this project is to make a simple clone of the classic Tetris game in VHDL.

The game can be uploaded to de board using the pre-built .sof in the `Built` folder.

## Controls

When the home screen is visible (the screen showing "Tetris") a few settings can be changed:

### Resolution (Switches 9 and 8)

| Switch position | Format name | Resolution | Refreshrate |
| :----: | :----: | :---------: | :--------: | :---------: |
| "00" | VGA | 640 x 480 | 60 |
| "01" | SVGA | 800 x 600 | 60 |
| "10" | XGA | 1024 x 768 | 60 |

### Demo mode (Switch 0)

| Switch position | Control mode |
| :-------------: | :----------: | 
| "0" | Game controlled by user |
| "1" | Game controlled by itself |

### In game user input (Buttons)

| Button | Action |
| :----: | :----: | 
| "3" | Move the current piece to the left |
| "2" | Drop the current piece |
| "1" | Move the current piece to the right |
| "0" | Rotate the current piece |

When chosen for a the user control mode, the game can be started by pressing either the left, right or rotate button on the home screen.

## Manually compiling and debugging the tetris game

The project can be loaded manually by opening the `Quartus/Tetris.qpf` within quartus prime, which should include all the necessary files and assignments. If debug cores of the architectural components need to be included, they can be enabled in the `signal tap logic analyzer` section within quartus.
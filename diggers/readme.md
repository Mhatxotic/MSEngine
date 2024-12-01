![Diggers logo](/docs/diggers.png?raw=true "Diggers logo")

# Diggers Fan Remake for MacOS, Linux and Windows

## Table of contents…
1. [Screenshots](#screenshots)…
2. [Status](#status)…
3. [System Requirements](#system-requirements)…
4. [Downloading](#downloading)…
5. [Running](#running)…
6. [About](#about)…
7. [Story](#story)…
8. [Objectives](#objectives)…
9. [Setup](#setup)…
10. [Controls](#controls)…
11. [Advanced](#advanced)…
12. [FAQ](#faq)…
13. [Credits](#credits)…
14. [Disclaimer](#disclaimer)…
15. [Contributing](#contributing)…
16. [License](#license)…

## [Screenshots](#screenshots)…
![Screenshots](/docs/diggers.webp?raw=true "Screenshots")

## [Status](#status)…
This Diggers fan remake was started in 2006 as a basic Win32 C application using DirectDraw, DirectSound and DirectMedia then rewritten from scratch in C++ from the ground up with a new fully customisable engine called *Mhatxotic Engine* to utilise open source, cross-platform technologies and conformed to ISO coding standards.

Diggers will always be a work-in-progress since it is difficult and incredibly time consuming to work on a game single-handedly and there are always issues with upstream code due to the balancing of modernisation and compatibility. However, the following information is the current estimated status of the game…

* *Engine:* `100%`…
  * _Windows:_ `100%`…
    * All functions accounted for.
  * _MacOS:_ `100%`…
    * All functions accounted for.
  * _Linux:_ `100%`…
    * Sometimes the full-screen/window toggle key might not work properly because of duplicated input keys. Hopefully will be fixed in Ubuntu 24.04 LTS.
    * Skipping one rendered frame every few seconds only on Wayland, perhaps when only using a `59.97hz` NTSC display. Probably need to make animations based on time and not frames which could be extremely difficult.
    * All other functions accounted for.
* *Graphics*: `100%`…
  * All other graphics accounted for.
* *Sound*: `100%`…
  * All music and sound accounted for.
* *Input*: `100%`…
  * Keyboard, mouse and controller accounted for but controller and keyboard inputs are suboptimal.
* *Levels*: `100%`…
  * All levels accounted for.
* *Gameplay*: `95%`…
  * Need proper ending movie with the stranger flying away in his pod.
  * All other gameplay accounted for.
* *Localisation*: `25%`…
  * No French book, intro nor UI localisations yet.
  * No German book, intro nor UI localisations yet.
  * No Italian book, intro nor UI localisations yet.
  * Only British translation so far.

## [System Requirements](#system-requirements)…
| | Minimum | Recommended | Note |
| --- | --- | --- | --- |
| **Processor** | Dual-Core 2GHz  | Multi-Core 2GHz+ | Multithreaded! |
| **System** *(Windows)* | XP SP3 *(X86/X64)* | 7/8.X/1X+ *(X64)* | 32 and 64bit executable. |
| **Memory** *(Windows)* | 16MB *(XP/X86)* | 128MB+ *(Win7/X64)* | Close estimate. |
| **System** *(MacOS)* | 10.7 *(Intel)* / 11 *(Arm)* | 13.0+ *(Arm)* | FAT Universal executable. |
| **Memory** *(MacOS)* | 256MB *(Intel)* | 512MB *(Arm)* | Close estimate. |
| **System** *(Linux)* | Ubuntu 23.10 *(X64)* | Ubuntu 23.04+ *(X64)* | See below for packages. |
| **Memory** *(Linux)* | 16MB | 128MB+ | Wild estimate. |
| **Graphics** | NV GF8K/ATI R600 | NV GF8K+/ATI R600+ | OpenGL 3.2 compatible. |
| **Audio** | Any sound device | Any sound device | OpenAL 1.1 compatible. |
| **Input** | Keyboard and mouse | Keyboard and mouse | Supports joystick! |
| **Disk Space** | 48MB (Read-Only) | 64MB (Read+Write) | Portable! |
| **Network** | None | None | Unused. |

## [Downloading](#downloading)…
You can always get the latest version of this project [here](https://github.com/Mhatxotic/Engine/releases).

## [Running](#running)…
### Windows version…
Running the Windows version should be trivial.

### Linux version…
The Linux version is linked against external packages that you need to install for the game to work. These packages can be installed with `sudo apt-get install libglfw3 libopenal1`.

### MacOS version…
The MacOS version is self-contained and only basic stdlibs are required to run which should already be included by default in any system. However, opening the disk image will require you to bypass Gatekeeper as I do not wish to sign it with personal information and have therefore used a self-signed certificate instead. To bypass Gatekeeper, simply run the `Terminal.app` and `chdir` to the directory where you downloaded the disk image with `chdir ~/Downloads` and then execute the following command to remove the quarantine flag from the disk image archive with `xattr -d com.apple.quarantine Diggers-R<x>-MacOS-Universal.dmg` where `<x>` is the version of this application. You should then be able to mount the disk image and run the game without any issue.

## [About](#about)…
Diggers is a puzzle video game for the Amiga CD32 in which the player takes control of a mining team excavating a planet for precious minerals. It was later released for the Amiga 1200 and DOS. Diggers was bundled with the CD32 at launch, along with a 2D platformer entitled Oscar on the same CD. A sequel, Diggers 2: Extractors, was released for DOS in 1995.

The game is set on the planet Zarg, where four races are vying for the gems and ores buried there. The four races are: the Habbish, who dig quickly and have high endurance, yet are impatient and prone to wander off; Grablins, who dig the fastest, have good stamina but are weak fighters; Quarriors, who are slow diggers but strong fighters; and the F'Targs, who are mediocre but regain their health quickly. The player chooses one of the four races, then sends out five man teams to mine a region. There are 34 regions in all, with two accessible at the beginning of the game. Each region has an amount of money the player must amass in order to beat it and open up the adjacent territories. Time plays a role, as there is always a computer controlled opposing race in the region, competing with the player to be the first to achieve the monetary goal.

The gameplay is similar in some ways to Lemmings, with the player issuing orders to his five miners, not directly controlling them. The stages themselves are viewed from the side - the mineshafts that extend throughout the levels give the impression of an anthill. The player commands his units to dig and, when needed, perform more specific actions such as picking up gems and fighting enemy diggers. The races have various personalities, and will occasionally do things without the player commanding them to; this can range from good (such as fighting an enemy) to very bad (walking into a deep pool of water and drowning). As the miners dig, rubies, gold, emeralds, and diamonds will appear.

At any time the player can teleport a miner back to the starting point and send him to the 'Zargon Stock Exchange', in order to trade the finds for money. Only three commodities are traded at one time, and the prices for each fluctuate depending on how much of a particular item has recently been sold. Here the player may also visit a shop and buy special mining tools, such as dynamite, automated drillers and bridge components. The miners themselves are expendable (though a monetary loss will be incurred for each lost worker), with a fresh set of five available each time a new level is entered.

## [Story](#story)…
This is no ordinary day on the planet, Zarg. Today is the glorius 412th. The day that each year, signals the commencement of one months frenzied digging. Four races of diggers, are tunneling their way to the Zargon Mineral Trading centre. they each, have an ambition, that requires them to mine as much as the planets mineral wealth, as possible.

Observing the quarrelsome diggers from afar, is a mysterious stranger. Each of the races are hoping that this stranger, will control their mining operations. His expertise, will be vital, in guiding them along the long, dangerous path that leads to their ultimate goal. His first step, is to register, at the Zargon Mineral Trading centre.

As the diggers wait nervously, the stranger heads toward the trading centre. for him, the ultimate test. the greatest challenge of his life lies ahead. the rewards for success, will be wealth unlimited. the results of failure, are unthinkable!

## [Objectives](#objectives)…
Guide one of the four available races to raising 17,500 Zogs by mining valuable minerals across 34 zones in order to build their dream creation.

## [Setup](#setup)…
Press `F1` at any time in the game to access the setup screen, `F2` to configure the key binds or `F3` to show the acknowledgements.

### Configuration screen…
* **Monitor**
  - Allows you to change the monitor the game will be displayed on. This is only useful if you have multiple monitors. Use 'Primary Monitor' if you don't care or have only one monitor.
* **Display State**
  * Allows you to play the game in full-screen or windowed mode.
  * **Windowed mode**
    - Play the game in a resizable/decorated window. You can control the size of this window by the appropriate window size option below.
  * **Borderless Full**
    - Play the game in a full-screen borderless window.
  * **Exclusive Full**
    - Play the game in exclusive full-screen mode. You can change the resolution with the appropriate full-screen size option below.
* **Full-Resolution**
  * Changes the full-screen resolution to play the game in. This option shows 'Disabled' if 'Display State' is not set to 'Exclusive full-screen mode'.
* **Window Size**
  * Changes the size of the window when 'Display State' is set to
  * **Windowed mode**
    - Disabled if not set as such.
  * **Automatic**
    - Sets the size of the window automatically that is appropriate for your desktop resolution.
* **Frame-Limiter**
  * Most games like this one will normally try to render the graphics as fast as possible this results in straining of the GPU with unneccesary screen tearing, power usage and heat. You only need to ever unlock the FPS to benchmarking reasons only as your monitor will only display frames at a fixed rate (normally 60fps [or 60hz]), thus it is advisable to turn this on to ensure longevity of your equipment. There will also be additional strain on the CPU as well as it sends commands to the GPU as fast as possible as well. Options available are...
  * **Adaptive VSync**
    - Turn on vertical synchronization only when the frame rate of the software exceeds the display's refresh rate, disabling it otherwise. That eliminates the stutter that occurs as the rendering engine frame rate drops below the display's refresh rate.
  * **None**
    - Renders as fast as possible.
  * **VSync only**
    - The video card is prevented from doing anything visible to the display memory until after the monitor finishes its current refresh cycle.
  * **Double VSync only**
    - Same as *VSync only* but limits to half the refresh rate.
  * **Adaptive VSync & Suspend**
    - Same as *Adaptive VSync* but adds a one millisecond suspend to the engine thread on the processor.
  * **Suspend Only**
    - Sane as *None* but only adds a one millisecond suspend to the engine thread on the processor.
  * **VSync & Suspend**
    - Same as *VSync only* and adds a one millisecond suspend to the engine thread on the processor.
  * **Double VSync & Suspend**
    - Same as *Double VSync only* and adds a one millisecond suspend to the engine thread on the processor.
* **Texture Filter**
  * Allows you to apply bilinear filtering to the game.
  * **Yes**
    - Bilinear filtering enabled by the GPU.
  * **No**
    - Point filtering (Retro and fastest).
* **Audio Device**
  - Allows you to select which device you want the game sound to play on. Leave it on 'Default' if you don't care. Note that if the device becomes unavailable. The game engine will try to re-initialise it, and if the device does not respond. The default audio device will be used. There may be a few seconds before any sort of detection occurs due to the way OpenAL works.
* **Volumes**
  - Self-explanitory. 100% is full volume (0 dB) and 0% is digital mute. Try not to use high volumes or there will be significant clipping on Windows XP systems, or annoying auto-normalisation of music and sound on Windows 7+ systems. Try to keep the values at three-quarters, i.e. 75%.

### Buttons…
* **APPLY**
  - Save the changes and set the new values.
* **DONE**
  - Return to game without saving or applying any changes.
* **RESET**
  - Resets all the settings to default and applys the default values.
* **BINDS**
  - Show the configure binds screen.
* **ABOUT**
  - Show the acknowledgements.

## [Controls](#controls)…
You can control the game with just a mouse which is novice difficulty like the Amiga computer and DOS version. Add use of the keyboard with the mouse makes the game quite easy to play. Playing with a controller is hard as it will basically emulate the mouse like the Amiga CD32 version of the game did.

If you move the cursor and the cursor becomes anything but an arrow graphic, then than particular item on the screen is selectable, e.g.
* 4 small arrows pointing to the centre…
  - Select/Perform action/Go here.
* 1 small arrow with `EXIT` underneath…
  - Exit out of particular area.
* 1 small arrow with `OK` underneath…
  - Accept/Select/Perform action/Go here.
* Arrow cursor pointing up/down/left or right…
  - Scroll.
* A ticking clock…
  - Control is blocked.

### In-game hud…
The hud is explained as follows from left to right…

* Money (4 digits)…
  - Shows how much currency you have. You must grab gems by digging for them, stealing them from your opponent, and then ordering the digger home to enter the trade centre, entering the bank, and selling your gems. Making enough currency wins the zone. You can also spend currency at the shop to buy items that will assist you on your operations.
* Inventory and health…
  - This part of the hud displays the gems and other items in your inventory which you can drop at any time by going to the digger inventory menu.
  - The health bar shows the health of your digger. It maxes out at 100% and will slowly regenerate if you stand still. It will turn orange if low and then turn red on imminent death. The heart changes speed depending on amount of health.
* Digger status…
  - This part of the hud shows what the selected digger is doing. This corresponds to the menu operation chosen.
* Digger buttons and indicators…
  - The numbers are clickable buttons which will quickly centre the view around the specified digger. You cannot click on the button if the corresponding digger has perished.
  - The indicators above the buttons indicate what the digger is doing…
    * Green: Digger is stopped and doing nothing.
    * Orange: Digger is moving.
    * Red: Digger is busy and cannot take orders until the current job is complete or is in danger.
    * Blue: The digger is in danger and the player must take action to save them from imminent death.
    * Black: The digger is impatient and the player must take action before they decide to do something else on their own.
* Utility buttons…
  - Cog: Centres around all your dropped and deployed inventory.
  - Hand: Shows all your diggers stats and inventory.
  - Arrows: Shows the position of all your diggers and what they're doing.
  - Question: Shows statistics and prediction information about the current zone operations.
  - Page: Displays the book.

### Aliases…
These aliases are for the explanations below. Note that keyboard defaults can
be seen by pressing the F2 key (by default) and will not be listed here.

| Alias | Meaning | Alias | Meaning |
| --- | --- | --- | --- |
| `MSE` | Refers to mouse | `JOY` | Refers to joystick |
| `LMB` | Left-Mouse Button | `RMB` | Right-Mouse Button |
| `MMB` | Middle-Mouse Button | `MWU` | Mouse Wheel up |
| `MWD` | Mouse Wheel Down | `MBx` | Mouse Button `x` |
| `JBx` | Joystick Button `x` | | |

### Playstation controller aliases…
| `JB0` | *Square* Button | `JB1` | *Cross* Button |
| `JB2` | *Circle* Button | `JB3` | *Triangle* Button |
| `JB4` | *L1* Button | `JB5` | *R1* Button |
| `JB6` | *L2* Button | `JB7` | *R2* Button |
| `JB8` | *Select* Button | `JB9` | *Start* Button |
| `JB10` | *L3* Button | `JB11` | *R3* Button |

### Anywhere in the game (not configurable)…
* `Alt`+`F4` on Windows or `Cmd`+`Q` on a Mac…
  - Instant quit. Any game progress is lost but engine settings and ALREADY SAVED game progress will be written to disk in a `.udb` file.
* `Alt`+`Enter`…
  - Switch between borderless or exclusive full-Screen and decorated window mode which will persist through app restarts.
* `World`+`F` on a Mac…
  - Switch between native full-screen and decorated window mode which may persist through app restarts using native functionality. Using the MacOS options disables the `Alt`+`Enter` logic and you have to exit native full-screen mode to be able to use that shortcut again.

### Anywhere in the game (but not during a fade transition…
* `JB8`…
  - Configure the game engine, video/audio settings, etc.
* `JOY` or `MSE` axes…
  - Move cursor on screen.
* `JB1` or `LMB`…
  - Select control under mouse cursor.

### Intro or title credits…
* `LMB` or `JB1`…
  - Skip cut-scene/intro.

### In-Level…
* `START`…
  - Pause the game.
* `LMB` or `JB1`…
  - Action, Select or Cancel menu.
* `RMB` or `JB2`…
  - Open menu for selected digger.

### In-Level (paused)…
* `JB3`+`JB4` or `MB3`+`MB4`…
  - Forfeit the game only when paused (Game over).

### Map Post-Mortem
* `JB3`, `JB4`, `MB3` or `MB4`…
  - Cycle between objects.

### In-shop/Race select screen…
* `MWU`, `MWD`, `JB4` or `JB5`…
  - Scroll available options.
* `JB1` or `LMB`…
  - Select item under cursor.

## [Advanced](#advanced)…
If for some reason you're an advanced-user or admin and need to fine tune how the game engine works, we have some command-line parameters that might be useful and you can overload as much as the operating system allows…

* Syntax: `diggers.exe cvar=value [cvar=value [...]]`

### Examples:-
* `diggers.exe vid_fs=1`
  - Will make the engine startup in full-screen.
* `diggers.exe con_disabled=0`
  - Will enable the developer console.
* `diggers.exe vid_fs=1 con_disabled=0`
  - Will make the engine startup in full-screen and enable the developer console.

You can change cvars by opening up the console with the `GRAVE` key (key under `ESCAPE` key). You will have to start the game with `con_disabled=0` in order for this to work. This key may not be available on most keyboards so you can change it by changing the `con_key1` or `con_key2` var. This is a GLFW specific key code. Once you're in the console, type `cmdlist` for the commands you can use or `cvarlist` for the settings you can change. In the release version of the game, the console is semi-permanantly disabled, you can re-enable the console by using `con_disabled=0` to re-enable it. CVars can obviously be overloaded onto the command-line, not just one setting.

## [F.A.Q.](#faq)…
* **Q. This does not 'look' like the original game.**
  - A. Well I've had to make a few changes because I want the remake to support 16:9 widescreen and ive had to modify and adapt most of the old textures that were originally in 320x200 (16:10), which is not a 4:3 resolution. If you can help upgrade the textures, that would be awesome!
* **Q. I got an error, strange behaviour or found a bug.**
  - A. You can start the game with the `log_file=...` (filename) parameter to give a pretty detailed log of what the app is doing so you can send me that along with as much info as possible such as the `.log` `.crt` `.dbg` and `.udb` files that the app generates. Neither of these files will contain any personal information, only technical information to help me squash the problem.
* **Q. I've picked the wrong game-engine settings and the game crashed/won't start.**
  - A. Try specifying the parameter `sql_defaults=1` command-line option to reset all the engine settings to default. If this doesn't work you'll have to delete the `.udb` file or set `sql_defaults=2` and start again from scratch thus losing all your Diggers saved game data. All that said though, the game shouldn't really crash though so please send me any logs/crash dumps you may have.
* **Q. Diggers crashed and then when I start Diggers on MacOS, nothing happens.**
  - A. If Diggers terminates uncleanly, you need to run it again manually with the `app_clearmutex=1` parameter. Also restarting your Mac helps but this is way too overkill. This problem does not affect Windows or Linux versions.
* **Q. Why does the game run faster than the Amiga version?**
  - A. A fixed polling frequency of 60hz is used for the game logic and I originally enjoyed playing this game on a 486 DX2/66 with the original MS-DOS version that ran at refresh frequency of 70hz (in 320x200 mode X) which is quite speedy compared to the slow gameplay of the Amiga version and I always preferred the fast logic of the MS-DOS version.
* **Q. Can I speed run or T.A.S. this game?**
  - A. This game is overkill on RNG but you can set the seed that makes the `math.random()` function predictable on the command-line with the `lua_randomseed=value` so hopefully you can use that to your advantage.

## [Credits](#credits)…
### Diggers for Amiga, CD32 and DOS…
* **Programmed by…**
  - *Mike Froggatt* (PC) and *Toby Simpson* (Amiga).
* **Additional DOS programming…**
  - *Keith Hook*.
* **Original design and Amiga programming…**
  - *Toby Simpson*.
* **Graphics…**
  - *Jason Wilson*.
* **Music and effects…**
  - *Richard Joseph* and *Graham King*.
* **Additional graphics…**
  - *Tony Heap* and *Jason Riley*.
* **Narrative text…**
  - *Martin Oliver*.
* **Additional design…**
  - *Michael Hayward*, *Ian Saunter* and *Tony Fagelman*.
* **Level design…**
  - *Toby Simpson* and *Tony Fagelman*.
* **Quality assurance…**
  - *Steve Murphy*, *Paul Dobson* and *Kelly Thomas*.
* **Intro & outro sequence…**
  - *Mike Ball* and *Mike Froggatt*.
* **Book production…**
  - *Alan Brand*, *Steve Loughran*, *Matrin Oliver* and *Tony Fagelman*.
* **Special thanks…**
  - *Chris Ludwig*, *Wayne Lutz*, *Dave Pocock*, *Sharon McGuffie* and *Ben Simpson*.
* **Produced By…**
  - *Tony Fagelman* and *Millennium*.

### Diggers fan remake for Windows, MacOS and Linux…
* **Complete conversion…**
  - By *Mhat* of *Mhatxotic Design*.
* **Setup music…**
  - *Super Stardust - Special Mission 1* by *PowerTrace*.
* **Credits music…**
  - *4U 07:00 V2001* by *Enuo*.
* **Game over music loop…**
  - *1000 Years Of Funk* by *Dimitri D. L.*.
* **Special thanks…**
  - [ModArchive.Org](https://www.modarchive.org).
  - [AmigaRemix.Com](https://www.amigaremix.com).

Please read [this document](/readme.md) on the third party software used in this game.

## [Disclaimer](#disclaimer)…
Diggers is *© Millennium Interactive Ltd. 1994* to which the company was [closed](https://www.mobygames.com/company/298/guerrilla-cambridge/) a long time ago. This game is *not* endorsed nor supported by any aforementioned persons and entities, nor anyone in the third-party engine credits either so please *do not* contact any of them for support. Any and all queries should *only* be directed to the dedicated [issues](https://github.com/Mhatxotic/Engine/issues) and [discussions](https://github.com/Mhatxotic/Engine/discussions) pages on GitHub.

## [Contributing](#contributing)…
See [this document](/contributing.md) for details on contributing to this project.

## [License](#license)…
Please read [this document](/license.md) for the license and disclaimer for use of this software.

## Copyright © 2006-2024 Mhatxotic Design. All Rights Reserved.

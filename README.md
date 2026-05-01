# IconsLib Framework

![Roblox](https://img.shields.io/badge/Roblox-000000?style=for-the-badge&logo=roblox&logoColor=white)
![Luau](https://img.shields.io/badge/Luau-00A2FF?style=for-the-badge&logo=lua&logoColor=white)
![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-red?style=for-the-badge) 

**Author:** Liver zMods

## What is this?
IconsLib was built to make UI development and scripting easier. Instead of hunting down icon IDs on external websites, this script provides a clean, animated, and highly optimized interface to search and copy icons on the fly.

![IconsLib UI Demonstration](./demo.png)

## Features
* **10+ Icon Libraries:** Includes Material Icons, Lucide, Phosphor, SF Symbols, Fluency, and more.
* **Anti-Lag Search:** Built-in debounce mechanism so typing fast won't freeze your game.
* **Smart Copying:** Choose exactly how you want the ID copied to your clipboard:
  * `ID Only` (e.g., 12345678)
  * Standard URL (e.g., `rbxassetid://12345678`)
* **Secure Copy:** Optional setting to require `Ctrl + Click` to prevent accidental clipboard overwrites.
* **Fully Animated:** Smooth hover effects, scaling, and transitions.
* **Multi-Language Support:** Auto-detects your system language (EN, PT, ES, VI).

## How to Use

Execute the script using your preferred executor or run it in Roblox Studio.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/LiverMods/IconsLib/refs/heads/main/main.lua"))()

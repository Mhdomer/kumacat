# KumaCat 🐾

Ultra-lightweight, hardware-accelerated animated runner for [Noctalia Shell](https://github.com/noctalia-dev/noctalia) on Wayland (Niri, Hyprland, Sway).

![KumaCat Preview](preview.png)

Inspired by RunCat and cosmic-runkat, redesigned from the ground up for zero-overhead performance, idle sleep state, interactive process radar with kill switches, pet mechanics, multi-sensor hardware telemetry, and an automated GIF importer.

---

## Features

* **Zero-Overhead Performance:**
  * Binds directly to Noctalia's internal `SystemStatService` singleton and sysfs files.
  * Spawns zero background subprocesses or bash loops during continuous animation.
  * GPU texture caching via Qt Quick scenegraph with Mesa hardware acceleration (Vulkan/OpenGL).
* **Idle Sleep Mode (0% CPU at Idle):**
  * When load drops below the threshold (default 5%) for over 12 seconds, the runner curls up to nap.
  * The animation timer is completely halted (`0 FPS`), eliminating wasted render cycles and battery drain.
* **Interactive Pet Micro-Interactions:**
  * Double-click the runner on the bar (or select "Pet KumaCat ♥" in the right-click menu) to pet the cat.
  * Triggers a hop bounce animation and floats playful heart/purr reaction emotes (`♥`, `meow~`, `purr~`, `✨`).
* **Multi-Sensor Hardware Drivers:**
  * **CPU Usage (%):** Smooth speed scaling proportional to overall CPU load.
  * **RAM Memory Pressure (%):** Runners pick up pace as system memory fills up.
  * **CPU Temperature (°C):** Speeds up dynamically as thermals climb.
  * **GPU Load / Activity (%):** Real-time GPU activity monitoring via direct sysfs read with thermal fallback.
  * **Network I/O Throughput:** Cat dashes during heavy downloads, git clones, and uploads, and rests when the network is quiet.
  * **Audio-Reactive Mode:** Runner pulses and speeds up to the beat of playing music via `SpectrumService`.
* **Process Radar with Terminate Kill Switch:**
  * Click the runner to open the interactive HUD card.
  * View real-time clock frequencies, memory usage, and the top 3 CPU-consuming processes.
  * Click the `✕` button next to any runaway process to instantly terminate it (`kill -15 <pid>`).
* **Sustained Turbo Alert Guardian:**
  * When load stays above the Turbo Threshold (default 85%) for 30 consecutive seconds, KumaCat fires a desktop warning notification so you can inspect runaway processes.
* **Multi-Monitor Display Filtering:**
  * Choose whether KumaCat runs on all connected monitor bars or strictly on your primary workstation screen.
* **Custom GIF & Sprite Auto-Importer:**
  * Built-in CLI tool (`./bin/kumacat-import`) extracts and formats any GIF, webp, or video into a clean runner pack with automatic dark-silhouette inversion for dark bars.
* **44 Bundled Runner Packs:**
  * Ships with 44 runners: Pixel Cat (Smooth 10-frame), Classic Cat, Swift Bird, Rubber Duck, Frog, Beagle, Shiba Inu, Flash Cat, Dojo Panda, and more.
* **Adaptive Theming:**
  * Monochrome runners automatically adapt to your active Noctalia color scheme (`mPrimary`, `mOnSurface`, `mError`, or Rainbow rave mode).
  * Color runners preserve their original full-color pixel art palette.

---

## Mouse Controls & Shortcuts

| Action | Control | Description |
| :--- | :--- | :--- |
| **Open HUD Card** | Left Click | Opens telemetry panel with Process Radar and runner carousel |
| **Pet the Cat** | Double Click | Playful hop animation with floating heart/purr reaction |
| **Pause / Resume** | Middle Click | Manually freeze or resume animation |
| **Context Menu** | Right Click | Open quick actions (Pet, Pause/Resume, Widget Settings) |

---

## Custom Runner Importer CLI

Import any GIF or video file directly into KumaCat with one command:

```bash
./bin/kumacat-import path/to/cat.gif --id nyan-cat --name "Nyan Cat" --author "PR-Gamer"
```

The importer automatically:
1. Slices frames to transparent 48px PNGs with Lanczos resampling.
2. Detects dark silhouettes and inverts them to pure white for dark bars (use `--no-invert` to keep original colors).
3. Generates `preview.png` and `sleep.png`.
4. Appends the metadata entry to `runners.json`.

---

## Installation in Noctalia

### Manual Symlink / Clone

Clone the repository into your projects directory and link it into your Noctalia plugins folder:

```bash
git clone https://github.com/Mhdomer/kumacat.git /mnt/data/Projects/kumacat
ln -s /mnt/data/Projects/kumacat ~/.config/noctalia/plugins/kumacat
```

Then add `"kumacat"` to your Noctalia plugins configuration in `~/.config/noctalia/plugins.json`:

```json
{
  "states": {
    "kumacat": {
      "enabled": true
    }
  }
}
```

Add the widget to your bar layout in `~/.config/noctalia/settings.json` under `bar.widgets`:

```json
{
  "id": "plugin:kumacat"
}
```

---

## Configuration

Right-click the runner on your bar and select **Widget Settings** (or run `qs -c noctalia-shell ipc call plugin openSettings kumacat`):

* **Active Runner:** Select from 44+ community runner templates.
* **Driving Metric:** Choose CPU, Memory, Temperature, GPU, or Network Throughput.
* **Audio-Reactive Speed:** Enable beat-reactive speed boosts for playing music.
* **Idle Sleep Mode:** Enable sleep state and configure sleep/turbo thresholds.
* **Sustained Turbo Alert:** Enable desktop warning notifications for prolonged high load.
* **Primary Screen Only:** Restrict runner to primary display or show across all monitors.
* **Color Mode:** Choose Pure White, Primary Accent, Secondary Accent, Error Red, or Rainbow Rave.
* **Runner Scale & Speed:** Tune scale multiplier (0.6x to 1.5x) and responsiveness (0.5x to 2.0x).

---

## Attribution & Credits

All bundled runners and frame animations maintain full attribution and licensing for their original designers. See [CREDITS.md](CREDITS.md) for full individual credits.

* **Takuto Nakamura ([@Kyome22](https://github.com/Kyome22)):** Original RunCat creator & 32 core runner designs (Apache 2.0).
* **Roy C. Davies ([@reality2-roycdavies](https://github.com/reality2-roycdavies)):** Smooth 10-frame pixel cat & sleeping sprite (MIT).
* **Community Contributors:** See [CREDITS.md](CREDITS.md).

---

## License

MIT License. See [LICENSE](LICENSE) for details.

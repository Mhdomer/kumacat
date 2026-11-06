# NoctaCat 🐾

Ultra-lightweight, hardware-accelerated animated runner for [Noctalia Shell](https://github.com/noctalia-dev/noctalia) on Wayland (Niri, Hyprland, Sway).

Inspired by RunCat and cosmic-runkat, redesigned from the ground up for zero-overhead performance, sleep state, process radar, and multi-sensor metrics.

---

## Features

* **Zero-Overhead Performance:**
  * Binds directly to Noctalia's internal `SystemStatService` singleton.
  * Spawns zero background subprocesses or bash loops during animation.
  * GPU texture caching via Qt Quick scenegraph with Mesa hardware acceleration (Vulkan/OpenGL).
* **Idle Sleep Mode (0% CPU at Idle):**
  * When load drops below the threshold (default 5%) for over 12 seconds, the runner curls up to nap.
  * The high-frequency animation timer is completely halted (`0 FPS`), eliminating wasted render cycles.
* **Overheat / Turbo State:**
  * When load crosses 85%, the capsule pulses with alert theming and turbo animation.
* **Multi-Sensor Drive:**
  * Drive runner speed by **CPU Load (%)**, **RAM Memory Pressure (%)**, **CPU Temperature (°C)**, or **Audio Spectrum Beats**.
* **Interactive HUD Popout Card:**
  * Click the cat on your bar to view real-time clock frequencies, memory usage, the **Process Radar** (Top 3 CPU-hogging processes), and a quick runner switcher.
* **44 Bundled Runner Packs:**
  * Ships with 44 runners: Pixel Cat (Smooth 10-frame), Classic Cat, Swift Bird, Rubber Duck, Frog, Beagle, Shiba Inu, Flash Cat, Dojo Panda, and more.
* **Adaptive Theming:**
  * Monochrome runners automatically adapt to your active Noctalia color scheme (`mPrimary`, `mOnSurface`, `mError`, or Rainbow mode).
  * Color runners preserve their original vibrant palette.

---

## Installation in Noctalia

### Manual Symlink / Clone

Clone the repository into your projects directory and link it into your Noctalia plugins folder:

```bash
git clone https://github.com/Mhdomer/noctacat.git /mnt/data/Projects/noctacat
ln -s /mnt/data/Projects/noctacat ~/.config/noctalia/plugins/noctacat
```

Then add `"noctacat"` to your Noctalia plugins configuration in `~/.config/noctalia/plugins.json`:

```json
{
  "states": {
    "noctacat": {
      "enabled": true
    }
  }
}
```

Add the widget to your bar layout in `~/.config/noctalia/settings.json` under `bar.widgets`:

```json
{
  "id": "plugin:noctacat"
}
```

---

## Configuration

Right-click the runner on your bar and select **Widget Settings** (or open Noctalia Settings -> Plugins -> NoctaCat):

* **Runner Character:** Pick from 44 community runners.
* **Driving Metric:** Choose CPU, Memory, or Temperature.
* **Sleep Mode:** Toggle sleep state and set the idle threshold.
* **Color Mode:** Choose Theme Default, Primary Accent, Error Red, or Rainbow.
* **Runner Scale & Offset:** Adjust size and vertical positioning inside the capsule.
* **Show Badge:** Display a percentage number badge directly next to the runner.

---

## Attribution & Credits

All runner assets belong to their respective creators under the Apache-2.0 and MIT licenses:
* **Takuto Nakamura ([@Kyome22](https://github.com/Kyome22))**: Original RunCat concept and 32 runner packs from [RunnerGallery](https://github.com/runcat-dev/RunnerGallery).
* **Roy C. Davies ([@reality2-roycdavies](https://github.com/reality2-roycdavies))**: Smooth 10-frame pixel cat and sleep sprite from `cosmic-runkat`.
* Community contributors: Ryan Token, Ishank Choudhary, Mao Kawaguchi, Lee Hyun Woo, kujira-wak, custsly, Sangyoon, KentaroxKondo, and sean.

See [CREDITS.md](CREDITS.md) for full details.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

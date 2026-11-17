# Radar de sensores

Native macOS app (Apple Silicon) for discovering sensors for ESP32 projects in health, home automation,
robotics, hydroponics, air quality, energy, wearables and security.

- Curated catalog of sensors with filters by sector, interface (`I2C`, `SPI`, `UART`, `Analógico`, `Trigger/Echo`, `RS485`, etc.), price, ownership (`Lo que ya tengo` / `Solo lo que no tengo`) and "what it measures"
- Direct search recommendations and **Project Recipes** (`Hidroponía DWC`, `Estación ambiental`, `Nodo biomédico`, `Sueño y caídas 60 GHz`) matched against owned hardware
- **ESP32 Node Architect** inside "Mi radar":
  - Direct and inventory-aware I2C address conflict detection
  - Electrical and bus audit (`UART` count, `ADC1` vs. Wi-Fi `ADC2` / `ADS1115` suggestion, 5 V and galvanic isolation warnings)
  - One-click **ESPHome YAML** and **ESP32-WROOM-32 pinout** generator
- **3D Isometric Figures & CAD Blueprints** for all 124 sensors:
  - Vectorized 3D isometric model on every catalog card with real millimeter dimensions (`L × W × H mm`)
  - Interactive Ficha 3D viewer with 3 modes: **Figura 3D** (with `Isométrica`, `Inclinada` and `Lateral 3D` perspectives), **Plano y cotas (mm)** (top & side views with Fusion 360 mounting specs), and **Comparar tamaño (1:1 scale)** against a `1 € coin (Ø 23.25 mm)`, `XIAO ESP32`, and `ESP32 DevKit`
  - Visual color-coded **module pinout bar** (`VIN`, `GND`, `SCL`, `SDA`, `TX`, `RX`, etc.), power consumption, and output signal details
- **Fusion 360 / 3D printing enclosure guidance** (`Carcasa (Fusion 360 / 3D)`) on every sensor sheet, plus direct links to STEP/CAD repositories (`GrabCAD`, `Printables`, `Adafruit CAD Parts`)
- **Actualizar** button (`⌘R`): scans RSS/Atom feeds of new products and filters "Novedades del mercado" with cross-language (Spanish ↔ English) matching
- Theme switcher (`Auto` / `Oscuro` / `Claro`, `⌘T`) and store/library links (`DigiKey.fi`, `Mouser.fi`, `Partco`, `Adafruit`, `ESPHome`, `PlatformIO`…)
- Monthly catalog curation by a Claude scheduled task

## Build

Requires the Xcode Command Line Tools (`xcode-select --install`).

```bash
bash build.sh
open ~/Applications/"Radar de sensores.app"
```

Live data is stored in `~/Applications/RadarSensores-datos/` (see `LEEME.md`).
Contributor and agent guidelines: [`AGENTS.md`](AGENTS.md).

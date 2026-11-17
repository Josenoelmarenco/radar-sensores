# Radar de sensores

Native macOS app (Apple Silicon) for discovering sensors for ESP32 projects in health, home automation,
robotics, hydroponics, air quality, energy, wearables and security.

- Curated catalog of sensors with filters by sector, interface (`I2C`, `SPI`, `UART`, `Analógico`, `Trigger/Echo`, `RS485`, etc.), price, ownership (`Lo que ya tengo` / `Solo lo que no tengo`) and "what it measures"
- Direct search recommendations and **Project Recipes** (`Hidroponía DWC`, `Estación ambiental`, `Nodo biomédico`, `Sueño y caídas 60 GHz`) matched against owned hardware
- **ESP32 Node Architect** inside "Mi radar":
  - Direct and inventory-aware I2C address conflict detection
  - Electrical and bus audit (`UART` count, `ADC1` vs. Wi-Fi `ADC2` / `ADS1115` suggestion, 5 V and galvanic isolation warnings)
  - One-click **ESPHome YAML** and **ESP32-WROOM-32 pinout** generator
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

# Radar de sensores

Native macOS app (Apple Silicon) for discovering sensors for ESP32 projects in health, home automation,
robotics, hydroponics, air quality, energy, wearables and security.

- Curated catalog of sensors with filters by sector, interface, price and "what it measures"
- Project ideas, combinations and I2C address conflict checks against owned hardware
- **Actualizar** button (⌘R): scans RSS feeds of new products and shows "Novedades del mercado"
- Store and library links (DigiKey, Mouser, Adafruit, ESPHome, GrabCAD…) for every sensor
- Monthly catalog curation by a Claude scheduled task

## Build

Requires the Xcode Command Line Tools (`xcode-select --install`).

```bash
bash build.sh
open ~/Applications/"Radar de sensores.app"
```

Live data is stored in `~/Applications/RadarSensores-datos/` (see `LEEME.md`).
Contributor and agent guidelines: [`AGENTS.md`](AGENTS.md).

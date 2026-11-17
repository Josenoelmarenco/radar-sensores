"""Validate catalogo.json for the Radar de sensores app.

Usage: python3 validar.py <folder-or-catalogo.json>
Prints OK or the list of problems (exit code 1).
"""
import json
import re
import sys
from pathlib import Path

FAM = {"bio", "radar", "imu", "dist", "vision", "aire", "clima", "luz", "fuerza", "agua", "sonido", "energia", "hmi", "pos", "ident", "com"}
SECTORES = {"salud", "domotica", "robotica", "agro", "ambiente", "energia", "wearables", "seguridad", "defensa"}
ETIQUETAS = {"esphome", "qwiic", "grove", "nuevo", "joya", "interno"}
BUSES = {"I2C", "SPI", "UART", "Analógico", "Digital", "I2S", "1-Wire", "Interno", "PWM", "Trigger/Echo", "RS485", "Placa propia", "CAN"}
TEMAS = {"productos", "sensores", "general"}


def main(arg):
    path = Path(arg)
    if path.is_dir():
        path = path / "catalogo.json"
    errors = []
    try:
        cat = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001 - report any read/parse problem
        print(f"ERROR: no se pudo leer {path}: {exc}")
        return 1

    if cat.get("esquema") != 1:
        errors.append("esquema debe ser 1")
    if not isinstance(cat.get("version"), int):
        errors.append("version debe ser un entero")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(cat.get("actualizado", ""))):
        errors.append("actualizado debe tener formato AAAA-MM-DD")
    for c in cat.get("cambios", []):
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(c.get("fecha", ""))) or not c.get("texto"):
            errors.append(f"cambio mal formado: {c}")
    for f in cat.get("fuentes", []):
        if not str(f.get("u", "")).startswith("https://") or f.get("tema") not in TEMAS or not f.get("n"):
            errors.append(f"fuente mal formada: {f}")

    sensores = cat.get("sensores")
    if not isinstance(sensores, list) or not sensores:
        errors.append("sensores debe ser una lista no vacía")
        sensores = []
    ids = set()
    for s in sensores:
        sid = s.get("id", "?")
        if not re.fullmatch(r"[a-z0-9]+", str(sid)):
            errors.append(f"{sid}: id inválido (solo minúsculas y números)")
        if sid in ids:
            errors.append(f"{sid}: id repetido")
        ids.add(sid)
        for key in ("pn", "n", "d"):
            if not isinstance(s.get(key), str) or not s.get(key).strip():
                errors.append(f"{sid}: falta {key}")
        if s.get("f") not in FAM:
            errors.append(f"{sid}: familia inválida {s.get('f')}")
        for key, allowed in (("s", SECTORES), ("t", ETIQUETAS), ("b", BUSES)):
            val = s.get(key)
            if not isinstance(val, list):
                errors.append(f"{sid}: {key} debe ser lista")
                continue
            bad = [x for x in val if x not in allowed]
            if bad:
                errors.append(f"{sid}: valores no válidos en {key}: {bad}")
        if not s.get("s"):
            errors.append(f"{sid}: necesita al menos un sector")
        if s.get("p") not in (0, 1, 2, 3, 4, None) or "p" not in s:
            errors.append(f"{sid}: p debe ser 0-4 o null")
        if s.get("l") not in (1, 2, 3):
            errors.append(f"{sid}: l debe ser 1, 2 o 3")
        if not isinstance(s.get("i"), list) or len(s.get("i")) != 2:
            errors.append(f"{sid}: i necesita exactamente 2 ideas")
        if not isinstance(s.get("c"), list):
            errors.append(f"{sid}: c debe ser lista")
        if "nuevo" in s.get("t", []) and not s.get("y"):
            errors.append(f"{sid}: etiqueta nuevo sin año y")
        if s.get("a") is not None and not re.fullmatch(r"0x[0-9A-F]{2}", str(s.get("a"))):
            errors.append(f"{sid}: dirección I2C inválida {s.get('a')} (formato 0x5A)")
    for s in sensores:
        sid = s.get("id", "?")
        ind = s.get("ind")
        if ind is not None and (not isinstance(ind, list) or not all(isinstance(x, list) and len(x) == 2 and all(isinstance(y, str) and y.strip() for y in x) for x in ind)):
            errors.append(f"{sid}: ind debe ser una lista de pares [industria, uso]")
        for key in ("eq", "how"):
            if key in s and (not isinstance(s[key], str) or not s[key].strip()):
                errors.append(f"{sid}: {key} debe ser texto")
        for c in s.get("c", []):
            if c not in ids:
                errors.append(f"{s.get('id')}: combina con un id que no existe: {c}")
    for k, v in (cat.get("propios") or {}).items():
        if k not in ids or v not in ("si", "kit"):
            errors.append(f"propios: entrada inválida {k}={v}")

    if errors:
        print("ERRORES:\n" + "\n".join(errors))
        return 1
    print(f"OK: {len(sensores)} sensores, versión {cat.get('version')}, actualizado {cat.get('actualizado')}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "."))

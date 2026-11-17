# Radar de sensores — carpeta de datos

La app **Radar de sensores** (`~/Applications/Radar de sensores.app`) lee y escribe aquí.

| Archivo | Quién lo escribe | Qué guarda |
|---|---|---|
| `catalogo.json` | La tarea mensual de Claude (y la app, la primera vez) | El catálogo curado de sensores |
| `novedades.json` | La app, al presionar **Actualizar** | Productos y noticias de sensores detectados en las fuentes RSS |
| `radar.json` | La app | Tu lista personal («Mi radar») |
| `meta.json` | La app | Fecha de la última búsqueda y novedades descartadas |

Si borras `catalogo.json`, la app vuelve a copiar el catálogo que trae incluido.
No edites `radar.json`, `novedades.json` ni `meta.json` con la app abierta: la app los sobrescribe.

## Esquema de `catalogo.json`

```
{
  "esquema": 1,
  "version": 2,                 // súmale 1 en cada actualización
  "actualizado": "AAAA-MM-DD",  // fecha de la actualización
  "cambios": [{"fecha": "AAAA-MM-DD", "texto": "Qué se agregó o corrigió"}],  // el más reciente primero
  "propios": {"<id>": "si" | "kit"},  // inventario: "si" = lo tiene; "kit" = en el kit SunFounder, sin verificar
  "fuentes": [{"n": "Nombre", "u": "https://…/feed/", "tema": "productos" | "sensores" | "general"}],
  "sensores": [ <sensor>, … ]
}
```

### Campos de cada sensor

| Campo | Obligatorio | Valor |
|---|---|---|
| `id` | sí | minúsculas, letras y números, único y estable |
| `pn` | sí | número de parte o nombre del módulo (`"SCD40 / SCD41"`) |
| `n` | sí | qué mide, en español, una línea |
| `f` | sí | familia: `bio radar imu dist vision aire clima luz fuerza agua sonido energia hmi pos ident com` |
| `s` | sí | sectores: `salud domotica robotica agro ambiente energia wearables seguridad defensa` |
| `b` | sí | interfaces: `I2C SPI UART Analógico Digital I2S 1-Wire Interno PWM Trigger/Echo RS485 CAN "Placa propia"`; `[]` si no se sabe |
| `a` | no | dirección I2C por defecto, formato `0x5A` |
| `p` | sí | precio de la placa común: `0` gratis, `1` <5 €, `2` 5–15 €, `3` 15–40 €, `4` >40 €, `null` desconocido |
| `l` | sí | dificultad `1` fácil, `2` medio, `3` avanzado |
| `t` | sí | etiquetas: `esphome qwiic grove nuevo joya interno` |
| `y` | si `t` tiene `nuevo` | año de lanzamiento, texto (`"2026"`) |
| `d` | sí | descripción en 1–2 frases |
| `i` | sí | exactamente 2 ideas de proyecto |
| `c` | sí | ids de sensores del catálogo con los que se combina |
| `w` | no | advertencia antes de conectar (voltaje, direcciones repetidas, red eléctrica) |
| `q` | no | término de búsqueda para tiendas si `pn` no sirve |
| `k` | no | palabras clave extra para el buscador, sin tildes |
| `ind` | no | industrias donde se usa esta tecnología: lista de pares `["Industria", "Para qué se usa"]` (2–4 pares) |
| `eq` | no | equivalente de grado industrial, una frase (qué se usa en un producto certificado) |
| `how` | no | principio físico específico de este sensor, 1–2 frases (si falta, la app usa el de su familia) |

Quita la etiqueta `nuevo` a los sensores que lleven más de 18 meses en el mercado.

### Sector `defensa`

Agrupa sensores de uso dual (navegación, conciencia situacional, robótica de campo, comunicaciones y autenticación) con enfoque defensivo y de protección civil. No agregues nada diseñado para armas, ni para interferir o suplantar comunicaciones. Si el sensor puede tener controles de exportación (cámaras térmicas, GNSS o IMU de alto rendimiento, radares), dilo en `w`.

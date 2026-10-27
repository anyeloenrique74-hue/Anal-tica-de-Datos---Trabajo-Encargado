"""Descarga por bloques el CSV de gasto del MEF y guarda solo las filas de las
universidades públicas: pliegos 510 a 599 del sector 10 (Educación).
Reanudable: guarda el avance en <salida>.estado.

Uso (desde la carpeta Entrega; requiere curl, incluido en Windows 10/11):
  python 03_Scripts/01_descargar_gasto_mef.py ^
    https://fs.datosabiertos.mef.gob.pe/datastorefiles/2025-Gasto-Mensual.csv ^
    04_Datos/raw/mef_2025/gasto_2025_universidades.csv
"""
import json
import os
import re
import subprocess
import sys
import time

url, salida = sys.argv[1], sys.argv[2]
os.makedirs(os.path.dirname(salida) or ".", exist_ok=True)
estado_f = salida + ".estado"
tmp = salida + ".bloque"
BLOQUE = 100_000_000


def es_universidad(linea):
    """Columnas 5 (SECTOR) y 7 (PLIEGO) del archivo del MEF."""
    campos = linea.split(b'","', 7)
    if len(campos) < 8:
        return False
    sector, pliego = campos[4], campos[6]
    return sector == b"10" and pliego.isdigit() and 510 <= int(pliego) <= 599


# curl usa el almacén de certificados de Windows
cab = subprocess.run(["curl", "-sSI", "-m", "60", url], capture_output=True, text=True).stdout
total = int(re.search(r"(?i)content-length:\s*(\d+)", cab).group(1))

if os.path.exists(estado_f):
    est = json.load(open(estado_f))
    offset, resto = est["offset"], bytes.fromhex(est["resto"])
else:
    offset, resto = 0, b""
    open(salida, "wb").close()

inicio = time.time()
while offset < total:
    fin = min(offset + BLOQUE, total) - 1
    try:
        subprocess.run(["curl", "-sS", "-m", "600", "-r", f"{offset}-{fin}", "-o", tmp, url], check=True)
        datos = open(tmp, "rb").read()
        if len(datos) != fin - offset + 1:
            raise IOError(f"bloque incompleto: {len(datos)}")
    except Exception as e:
        print("reintento en 30 s:", e, flush=True)
        time.sleep(30)
        continue
    buf = resto + datos
    if fin == total - 1:
        lineas, resto = buf.split(b"\n"), b""
    else:
        corte = buf.rfind(b"\n")
        lineas, resto = buf[:corte].split(b"\n"), buf[corte + 1:]
    with open(salida, "ab") as f:
        for i, ln in enumerate(lineas):
            if (offset == 0 and i == 0) or es_universidad(ln):
                f.write(ln.rstrip(b"\r") + b"\n")
    offset = fin + 1
    json.dump({"offset": offset, "resto": resto.hex()}, open(estado_f, "w"))
    print(f"{offset / total:6.1%}  {(time.time() - inicio) / 60:5.1f} min", flush=True)

os.remove(estado_f)
os.remove(tmp)
print("listo")

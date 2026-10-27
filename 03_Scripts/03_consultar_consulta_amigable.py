"""Descarga de la Consulta Amigable del MEF el presupuesto 2025 de cada pliego
del sector Educación (Gobierno Nacional), para validar nuestros datos.
Uso: python 03_consultar_consulta_amigable.py <cookies.txt> <salida.csv>"""
import csv
import html
import re
import subprocess
import sys
import urllib.parse

BASE = "https://apps5.mineco.gob.pe/transparencia/Navegador/Navegar_7.aspx?y=2025&ap=ActProy"
JAR, SALIDA = sys.argv[1], sys.argv[2]


def curl(data=None):
    cmd = ["curl", "-sSL", "-m", "120", "-A", "Mozilla/5.0", "-c", JAR, "-b", JAR, BASE]
    if data is not None:
        cmd += ["--data-binary", urllib.parse.urlencode(data)]
    return subprocess.run(cmd, capture_output=True).stdout.decode("utf-8", "replace")


def campos(page):
    d = {}
    for m in re.finditer(r'<input[^>]+type="hidden"[^>]*>', page):
        n = re.search(r'name="([^"]+)"', m.group(0))
        v = re.search(r'value="([^"]*)"', m.group(0))
        if n:
            d[n.group(1)] = html.unescape(v.group(1)) if v else ""
    return d


def filas(page):
    """Filas de la tabla de resultados: (valor del radio, celdas de texto)."""
    out = []
    for tr in re.findall(r"<tr[^>]*>(.*?)</tr>", page, re.S):
        radio = re.search(r'name="grp1"[^>]*value="([^"]*)"', tr) or re.search(r'value="([^"]*)"[^>]*name="grp1"', tr)
        celdas = [re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", c))).strip()
                  for c in re.findall(r"<td[^>]*>(.*?)</td>", tr, re.S)]
        celdas = [c for c in celdas if c]
        if radio and celdas:
            out.append((radio.group(1), celdas))
    return out


def boton(page, nombre, seleccion=None):
    d = campos(page)
    d["__EVENTTARGET"] = ""
    d["__EVENTARGUMENT"] = ""
    d["ctl00$CPH1$DrpYear"] = "2025"
    d["ctl00$CPH1$DrpActProy"] = "ActProy"
    d[nombre] = "x"
    if seleccion is not None:
        d["grp1"] = seleccion
    return curl(d)


p = curl()
p = boton(p, "ctl00$CPH1$BtnTipoGobierno")
f = filas(p)
nac = [v for v, c in f if "NACIONAL" in c[0].upper()][0]
p = boton(p, "ctl00$CPH1$BtnSector", nac)
f = filas(p)
edu = [v for v, c in f if "EDUCACION" in c[0].upper()][0]
p = boton(p, "ctl00$CPH1$BtnPliego", edu)
COLS = ["pliego", "pliego_nombre", "pia", "pim", "certificacion", "compromiso_anual",
        "atencion_compromiso_mensual", "devengado", "girado", "avance_pct"]
with open(SALIDA, "w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh)
    w.writerow(COLS)
    for _, c in filas(p):
        codigo, nombre = c[0].split(": ", 1)
        w.writerow([codigo, nombre] + [x.replace(",", "") for x in c[1:9]])
print("filas guardadas en", SALIDA)

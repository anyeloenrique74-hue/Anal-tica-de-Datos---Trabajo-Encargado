# =============================================================================
# 02_preparar_presupuesto.R
# Prepara la base de presupuesto y ejecución del gasto 2025 de las
# universidades públicas, a partir del archivo que genera
# 01_descargar_gasto_mef.py.
#
# Fuente: MEF, dataset "Presupuesto y Ejecución de Gasto" (2025-Gasto-Mensual.csv)
# https://www.datosabiertos.gob.pe/dataset/presupuesto-y-ejecución-de-gasto
#
# Ejecutar con la carpeta "Entrega" como directorio de trabajo.
# =============================================================================

library(data.table)
library(dplyr)
library(janitor)

archivo_raw <- "04_Datos/raw/mef_2025/gasto_2025_universidades.csv"
carpeta_out <- "04_Datos/procesado"
if (!file.exists(archivo_raw)) {
  stop("No se encuentra ", archivo_raw, ". Ubícate en la carpeta 'Entrega' con setwd() ",
       "y genera el archivo con 03_Scripts/01_descargar_gasto_mef.py.")
}
dir.create(carpeta_out, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------------
# 1. Lectura
# El archivo trae las filas de los pliegos 510 a 599 del sector Educación, que
# corresponden a las universidades públicas. Se lee todo como texto para no
# perder los ceros de los códigos.
# -----------------------------------------------------------------------------
gasto <- fread(archivo_raw, colClasses = "character", encoding = "UTF-8") %>%
  as_tibble() %>%
  clean_names()

pasos <- list()
anotar <- function(paso, d) {
  pasos[[length(pasos) + 1]] <<- tibble(paso = paso, filas = nrow(d),
                                        universidades = n_distinct(d$pliego))
}
anotar("Filas descargadas (pliegos 510 a 599, sector Educación)", gasto)

# Comprobación: todas las filas son de universidades del Gobierno Nacional
stopifnot(all(gasto$nivel_gobierno == "E"), all(gasto$sector == "10"),
          all(between(as.integer(gasto$pliego), 510, 599)))

# -----------------------------------------------------------------------------
# 2. Tipos de dato y variables nuevas
# Las filas con mes_eje = 0 traen el presupuesto del año (PIA y PIM); las de
# los meses 1 a 12 traen la ejecución de ese mes.
# -----------------------------------------------------------------------------
# "U.N. AGRARIA DE LA SELVA" -> "Agraria de la Selva"
nombre_corto <- function(x) {
  x <- tools::toTitleCase(tolower(sub("^U[.] ?N[.] ", "", x)))
  for (p in c("De", "Del", "La", "Las", "Los", "Y")) {
    x <- gsub(paste0(" ", p, " "), paste0(" ", tolower(p), " "), x)
  }
  x
}

montos <- c("monto_pia", "monto_pim", "monto_certificado", "monto_comprometido_anual",
            "monto_comprometido", "monto_devengado", "monto_girado")

gasto <- gasto %>%
  mutate(
    across(all_of(montos), as.numeric),
    mes_eje = as.integer(mes_eje),
    tipo_fila = if_else(mes_eje == 0, "Presupuesto del año", "Ejecución del mes"),
    universidad = nombre_corto(pliego_nombre),
    es_unas = pliego == "526"
  )

# -----------------------------------------------------------------------------
# 3. Resumen por universidad
# Avance = devengado / PIM, el indicador que usa el MEF en la Consulta Amigable.
# -----------------------------------------------------------------------------
resumen <- gasto %>%
  group_by(pliego, universidad, es_unas) %>%
  summarise(across(all_of(montos), sum), .groups = "drop") %>%
  arrange(desc(monto_devengado / monto_pim)) %>%
  mutate(avance_pct = round(100 * monto_devengado / monto_pim, 1),
         puesto = row_number())

# -----------------------------------------------------------------------------
# 4. Guardar
# -----------------------------------------------------------------------------
registro <- bind_rows(pasos)

saveRDS(gasto, file.path(carpeta_out, "presupuesto_universidades_2025.rds"))
write.csv(resumen, file.path(carpeta_out, "resumen_universidades_2025.csv"), row.names = FALSE)
write.csv(registro, file.path(carpeta_out, "registro_presupuesto.csv"), row.names = FALSE)

print(registro)
cat("\nUniversidades:", nrow(resumen), "\n")
cat("PIM total: S/", format(round(sum(resumen$monto_pim)), big.mark = ","),
    " Devengado: S/", format(round(sum(resumen$monto_devengado)), big.mark = ","),
    " Avance:", round(100 * sum(resumen$monto_devengado) / sum(resumen$monto_pim), 1), "%\n")
print(filter(resumen, es_unas) %>% select(universidad, monto_pia, monto_pim, monto_devengado, avance_pct, puesto))

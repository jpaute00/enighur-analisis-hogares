# enighur-analisis-hogares
Análisis del ingreso y gasto de los hogares en Ecuador con datos ENIGHUR 2024-2025 (INEC), comparando el nivel Nacional con Región Sierra, Cantón Ambato, Provincia Sucumbíos y Provincia Carchi. Proyecto de Introducción a la Estadística — ESPOL.
# Análisis de Ingresos y Gastos de los Hogares en Ecuador (ENIGHUR 2024-2025)

Proyecto de mejoramiento de la materia **Introducción a la Estadística**, desarrollado junto a [Carlos Morales], usando microdatos de la **Encuesta Nacional de Ingresos y Gastos de los Hogares Urbanos y Rurales (ENIGHUR)** del INEC, período 2024-2025.

## 🎯 Objetivo

Analizar el ingreso corriente per cápita y la estructura del gasto de consumo de los hogares ecuatorianos, comparando el nivel Nacional contra cuatro territorios asignados (Grupo 12):

- 🇪🇨 Nacional
- ⛰️ Región Sierra
- 🏙️ Cantón Ambato
- 🌳 Provincia Sucumbíos
- 🏔️ Provincia Carchi

## 📊 Contenido del repositorio

| Archivo | Descripción |
|---|---|
| `Proyecto_Grupo12.Rmd` | Script principal en R Markdown: limpieza de datos, cálculo de deciles/cuartiles con metodología INEC, diseño muestral complejo (`survey`/`srvyr`), y generación de todos los gráficos |
| `Scripts auxiliares/Deciles.R` | Función auxiliar para el cálculo de deciles y cuartiles ponderados, replicando la metodología del INEC |
| `Datos/` | Base de microdatos ENIGHUR 2024-2025 (no incluida por tamaño/licencia — descargar desde el [portal oficial del INEC](https://www.ecuadorencifras.gob.ec/)) |
| `graficos/` | Imágenes exportadas: diagrama de caja y bigote, ojiva de ingresos, gasto por decil, estructura del gasto |

## 🔎 Metodología

- Cálculo de deciles y cuartiles de ingreso corriente per cápita, ponderados por el factor de expansión (`Fexp`)
- Diseño muestral complejo declarado una sola vez a nivel nacional (`as_survey_design`), y estimación por dominio (`filter()`) para cada territorio — preservando la estructura de estratos/UPM para un cálculo correcto del error estándar
- Visualización con `ggplot2`, `ggtext` y `patchwork`

## 📈 Hallazgos principales

- 💰 El ingreso corriente per cápita es más alto en **Cantón Ambato** ($471,1) y **Región Sierra** ($470,8), ambos por encima del promedio **Nacional** ($411,4), mientras que **Provincia Sucumbíos** ($334,7) y **Provincia Carchi** ($344,2) registran los valores más bajos.
- 📈 El gasto de consumo crece fuertemente con el ingreso en los cinco territorios: los hogares del Decil 10 gastan en promedio hasta 5 veces más que los del Decil 1.
- 🍽️ Se confirma la **Ley de Engel** en todos los territorios: a medida que sube el ingreso, el gasto en alimentos pierde peso relativo, mientras que restaurantes, alojamiento y seguros ganan participación.
- 🏠 La vivienda se mantiene como un gasto proporcionalmente alto y estable en los territorios de menor ingreso (Carchi, Sucumbíos), incluso en los deciles más altos.

## 🛠️ Tecnologías

R · tidyverse · survey/srvyr · ggplot2 · ggtext · patchwork · showtext

## 📚 Fuente

INEC (2026). *Encuesta Nacional de Ingresos y Gastos de los Hogares Urbanos y Rurales (ENIGHUR), 2024-2025.*

---
Proyecto académico — Facultad de Ciencias Naturales y Matemáticas, ESPOL

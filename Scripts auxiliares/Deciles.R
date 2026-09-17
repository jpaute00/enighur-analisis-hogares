# ==============================================================================
# SCRIPT 02.2: INGRESO CORRIENTE MENSUAL DE LOS HOGARES
# CUADROS 2.2.1 al 2.2.6
# USANDO BASE MAESTRA AIG
# ==============================================================================

library(survey)
library(openxlsx)
library(dplyr)

options(survey.drop.empty.groups = FALSE)
options(survey.lonely.psu = "adjust")
options(scipen = 999)


# ==============================================================================
# FUNCIONES LOCALES PARA DECILES / NTILES PONDERADOS
# ==============================================================================
# Se incluyen dentro del script para no depender de 00_UTILIDADES_FORMATO_LIMPIEZA.R.

resumen_deciles_svy <- function(data, variable_decil = "Decil", variable_orden = "ing_cor_per", peso = "Fexp") {
  data <- as.data.frame(data)
  if(nrow(data) == 0 || !(variable_decil %in% names(data))) {
    return(data.frame(
      Decil = integer(0),
      hogares_muestra = integer(0),
      hogares_expandido = numeric(0),
      min_variable_orden = numeric(0),
      max_variable_orden = numeric(0)
    ))
  }
  
  grupos <- sort(unique(data[[variable_decil]][!is.na(data[[variable_decil]])]))
  
  out <- lapply(grupos, function(g) {
    dd <- data[data[[variable_decil]] == g & !is.na(data[[variable_decil]]), , drop = FALSE]
    data.frame(
      Decil = g,
      hogares_muestra = nrow(dd),
      hogares_expandido = sum(dd[[peso]], na.rm = TRUE),
      min_variable_orden = min(dd[[variable_orden]], na.rm = TRUE),
      max_variable_orden = max(dd[[variable_orden]], na.rm = TRUE)
    )
  })
  
  if(length(out) == 0) {
    return(data.frame(
      Decil = integer(0),
      hogares_muestra = integer(0),
      hogares_expandido = numeric(0),
      min_variable_orden = numeric(0),
      max_variable_orden = numeric(0)
    ))
  }
  
  do.call(rbind, out)
}

calcular_ntiles_spss <- function(
    data,
    variable,
    nombre_decil = "Decil",
    peso = "Fexp",
    grupos = 10,
    desempate = NULL,
    etiqueta = "",
    mostrar_control = FALSE
) {
  data <- as.data.frame(data)
  
  vars_req <- c(variable, peso)
  faltan <- setdiff(vars_req, names(data))
  if(length(faltan) > 0) {
    stop(paste("Faltan variables para calcular NTILES tipo SPSS:", paste(faltan, collapse = ", ")))
  }
  
  data[[variable]] <- suppressWarnings(as.numeric(data[[variable]]))
  data[[peso]] <- suppressWarnings(as.numeric(data[[peso]]))
  
  data[[nombre_decil]] <- NA_integer_
  
  idx <- which(
    !is.na(data[[variable]]) & is.finite(data[[variable]]) &
      !is.na(data[[peso]]) & is.finite(data[[peso]]) & data[[peso]] > 0
  )
  
  if(length(idx) == 0) {
    return(data)
  }
  
  dd <- data[idx, , drop = FALSE]
  
  if(!is.null(desempate) && desempate %in% names(dd)) {
    ord <- order(dd[[variable]], dd[[desempate]], na.last = TRUE)
  } else {
    ord <- order(dd[[variable]], seq_len(nrow(dd)), na.last = TRUE)
  }
  
  dd_ord <- dd[ord, , drop = FALSE]
  dd_ord$.pos_original_ntile <- idx[ord]
  
  grupos_valor <- split(seq_len(nrow(dd_ord)), dd_ord[[variable]], drop = TRUE)
  
  total_w <- sum(dd_ord[[peso]], na.rm = TRUE)
  acum_previo <- 0
  
  deciles_asignados <- integer(nrow(dd_ord))
  
  for(g in seq_along(grupos_valor)) {
    ii <- grupos_valor[[g]]
    w_bloque <- sum(dd_ord[[peso]][ii], na.rm = TRUE)
    
    pos_media <- (acum_previo + (w_bloque / 2)) / total_w
    
    dec <- floor(pos_media * grupos) + 1
    dec <- max(1, min(grupos, dec))
    
    deciles_asignados[ii] <- as.integer(dec)
    acum_previo <- acum_previo + w_bloque
  }
  
  data[[nombre_decil]][dd_ord$.pos_original_ntile] <- deciles_asignados
  
  if(mostrar_control) {
    cat("\nDeciles ponderados tipo NTILES", ifelse(etiqueta == "", "", paste0(" - ", etiqueta)), ":\n", sep = "")
    print(resumen_deciles_svy(data, variable_decil = nombre_decil, variable_orden = variable, peso = peso))
  }
  
  data
}


# ==============================================================================
# FUNCIÓN LOCAL: NTILES PONDERADOS TIPO SPSS POR DOMINIO
# ==============================================================================
# Permite reproducir las variables usadas en SPSS:
# dec_nac_per, dec_area_per, dec_region_per, dec_cant_per, dec_ciud_per y dec_prov_per.
calcular_ntiles_spss_por_grupo <- function(
    data,
    variable,
    grupo_vars,
    nombre_decil,
    peso = "Fexp",
    grupos = 10,
    desempate = "Identif_hog"
) {
  
  data <- as.data.frame(data)
  data[[nombre_decil]] <- NA_integer_
  
  vars_req <- c(variable, peso, grupo_vars)
  faltan <- setdiff(vars_req, names(data))
  
  if(length(faltan) > 0) {
    stop(
      paste(
        "Faltan variables para calcular NTILES por grupo:",
        paste(faltan, collapse = ", ")
      )
    )
  }
  
  idx_validos <- which(
    !is.na(data[[variable]]) & is.finite(as.numeric(data[[variable]])) &
      !is.na(data[[peso]]) & is.finite(as.numeric(data[[peso]])) &
      as.numeric(data[[peso]]) > 0
  )
  
  if(length(idx_validos) == 0) {
    return(data)
  }
  
  # Excluir registros sin dominio en cualquiera de las variables de grupo.
  for(gv in grupo_vars) {
    idx_validos <- idx_validos[!is.na(data[[gv]][idx_validos])]
  }
  
  if(length(idx_validos) == 0) {
    return(data)
  }
  
  llave <- interaction(
    data[idx_validos, grupo_vars, drop = FALSE],
    drop = TRUE,
    lex.order = TRUE
  )
  
  grupos_idx <- split(idx_validos, llave)
  
  for(nm in names(grupos_idx)) {
    
    ii <- grupos_idx[[nm]]
    
    tmp <- calcular_ntiles_spss(
      data = data[ii, , drop = FALSE],
      variable = variable,
      nombre_decil = nombre_decil,
      peso = peso,
      grupos = grupos,
      desempate = desempate,
      etiqueta = "",
      mostrar_control = FALSE
    )
    
    data[[nombre_decil]][ii] <- tmp[[nombre_decil]]
  }
  
  data
}


# INGRESOSH <- calcular_ntiles_spss(
#   data = BASE_INGRESOS_FINAL,
#   variable = "ing_cor_per",
#   nombre_decil = "dec_nac_per",
#   peso = "Fexp",
#   grupos = 10,
#   desempate = "Identif_hog",
#   etiqueta = "2.2.1 nacional",
#   mostrar_control = FALSE
# )


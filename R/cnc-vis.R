# ```{r pkgs, message=FALSE, warning=FALSE, echo=FALSE}
knitr::opts_chunk$set(echo = FALSE, message = FALSE, warning = FALSE)
library(magrittr)
library(tidyverse)
library(stringr)
library(forcats)
library(lubridate)
library(leaflet)
library(cnc)
data(br_uf_map, package = 'abjData')
data(pnud_uf, package = 'abjData')
data(pnud_min, package = 'abjData')
data(cadmun, package = 'abjData')

pnud_min %<>%
  filter(ano == 2010) %>% 
  count(regiao, id = uf) %>% 
  rename(n_muni = n)
cadmun %<>% distinct(cod, uf) %>% mutate_all(as.character)
pnud_uf %<>% 
  filter(ano == 2010) %>% 
  select(uf, ufn, popt) %>% 
  mutate(uf = as.character(uf)) %>% 
  inner_join(cadmun, c('uf' = 'cod')) %>% 
  select(id = uf.y, ufn, popt) %>% 
  inner_join(pnud_min, 'id')

g <- "/home/jtrecenti/abj/kml-brasil/lib/2010/estados/geojson" %>% 
  dir(full.names = TRUE) %>% 
  purrr::map(geojsonio::geojson_read, what = 'sp')
feat <- g %>% 
  purrr::map(~.x@lines) %>% 
  purrr::reduce(append)
feat %>% 
  seq_along() %>% 
  purrr::walk(~{feat[[.x]]@ID <<- as.character(.x)})
g2 <- g[[1]]
g2@lines <- feat
g2@data <- g %>% 
  purrr::map_df(~dplyr::mutate_all(.x@data, as.character)) %>% 
  janitor::clean_names() %>% 
  tibble::rownames_to_column('id') %>% 
  tibble::as_tibble()
# ```

# ```{r df}
cnc_vis <- tidy_cnc %>% 
  filter(dt_cadastro < '2016-07-01', # escopo
         # só transito em julgado
         tipo_pena == 'Trânsito em julgado', 
         # sem assunto penal
         !assunto_penal_any,
         # julgou depois de distribuir.
         dt_pena > dt_propositura,
         # ficou com n quase zero aqui.
         instancia == '1 grau') %>% 
  # se valores  são NA ou <= 0, teve_* correspondente é FALSE
  mutate_at(vars(starts_with('vl_')), 
            funs(if_else(. <= 0 | . > 5e7, NA_real_, .))) %>% 
  mutate(teve_multa = !is.na(vl_multa),
         teve_ressarcimento = !is.na(vl_ressarcimento),
         teve_perda_bens = !is.na(vl_perda_bens)) %>% 
  # se durações são NA ou <= 0, teve_* correspondente é FALSE
  mutate_at(vars(starts_with('duracao_')), 
            funs(if_else(. <= 0, NA_real_, .))) %>% 
  mutate(teve_suspensao = !is.na(duracao_suspensao),
         teve_proibicao = !is.na(duracao_proibicao)) %>% 
  # tempo de condenacao
  select(-teve_pena) %>% 
  # criando um teve_all e modificando os teve_* para character
  mutate(tempo_condenacao = as.numeric(dt_pena - dt_propositura)) %>% {
    d <- .
    nms <- d %>% select(starts_with('teve_')) %>% names()
    nms_clean <- nms %>% str_replace_all('^teve_', '')
    purrr::walk2(nms, nms_clean, ~{
      d[[.x]] <<- d[[.x]] %>% 
        if_else(.y, 'NA') %>% 
        type.convert(as.is = TRUE)
    })
    d
  } %>% 
  unite(teve_all, starts_with('teve_'), sep = ',', remove = FALSE) %>% 
  mutate(teve_all = teve_all %>% 
           str_replace_all(',NA|^NA,(NA,)*|NA$', '')) %>%
  select(id_condenacao, id_processo, id_pessoa,
         # condenacoes
         dt_condenacao = dt_pena, tempo_condenacao,
         starts_with('teve_'),
         starts_with('vl_'),
         starts_with('de_'), -de_pena,
         -starts_with('ate_'),
         starts_with('duracao_'), -duracao_pena, -ends_with('_regex'),
         starts_with('assunto_cod'), -assunto_cod_5,
         starts_with('assunto_nm'), -assunto_nm_5,
         # processos
         n_processo, dt_cadastro, dt_propositura,
         esfera_processo, tribunal, instancia,
         comarca_secao, vara_camara, uf_processo,
         # pessoas
         tipo_pessoa, nm_pessoa, sexo, 
         publico, esfera, orgao, cargo
  ) %>% 
  # unite(assunto_cod_all, starts_with('assunto_cod'), sep = ',') %>% 
  # unite(assunto_nm_all, starts_with('assunto_nm'), sep = ',') %>% 
  nest(starts_with('assunto_nm_')) %>% 
  mutate(assunto_nm_all = map_chr(data, ~{
    .x %>% 
      gather() %>% 
      filter(!is.na(value)) %>% 
      arrange(value) %>% 
      with(value) %>% 
      paste(collapse = ',')
  })) %>% 
  select(-matches('^data$|^assunto_nm_[0-9]')) %>% 
  nest(starts_with('assunto_cod_')) %>% 
  mutate(assunto_cod_all = map_chr(data, ~{
    .x %>% 
      gather() %>% 
      filter(!is.na(value)) %>% 
      arrange(value) %>% 
      with(value) %>% 
      paste(collapse = ',')
  })) %>% 
  select(-matches('^data$|^assunto_cod_[0-9]')) %>% 
  arrange(floor_date(dt_cadastro, 'day'), as.numeric(id_processo)) %>% 
  left_join(select(pnud_uf, id, regiao), c('uf_processo' = 'id'))
# ```

tidy_improb <- cnc_vis
source('/home/jtrecenti/abj/inacSite/R/add_uf_consolidado.R')
cnc_vis <- cnc_vis %>% 
  ungroup() %>% 
  mutate(uf_processo2 = troca_string_por_regex(comarca_secao, lista_de_regex),
         uf_processo2 = str_replace_all(uf_processo2, "regex_", ""),
         uf_processo3 = ifelse(str_detect(uf_processo2, "^[a-z]{2}$"), uf_processo2, as.character(NA)),
         uf_processo = str_to_upper(ifelse(is.na(uf_processo), uf_processo3, uf_processo))) %>% 
  select(-uf_processo2, -uf_processo3)


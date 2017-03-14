print_var <- function(v) {
  
  tidy_vis <- tidy_cnc %>% 
    filter(esfera_processo %in% c('Estadual', 'Federal'),
           instancia %in% c('1 grau', '2 grau'),
           tipo_pena == 'Trânsito em julgado',
           !assunto_penal_any)
  x <- stringr::str_replace_all(sort(unique(tidy_vis[[v]])), ' +', '_')
  nms <- stringr::str_to_title(stringr::str_replace_all(x, '_', ' '))
  lab <- stringr::str_to_title(stringr::str_replace_all(v, '_', ' '))
  shiny::selectInput(v, lab, purrr::set_names(paste0('_', x), nms)) %>% 
    as.character() %>% 
    xml2::read_html() %>% 
    rvest::html_node(paste0('#', v)) %>% 
    as.character() %>% 
    cat()
}

# print_var('esfera_processo')
# print_var('instancia')

# tabela unidimensional
tabela <- function(d, ..., kable = TRUE) {
  l <- list(...)
  tab <- d %>% 
    dplyr::distinct_(l$id, .keep_all = TRUE) %>% 
    dplyr::filter_(l$f) %>% 
    dplyr::count_(l$v1, sort = TRUE) %>% 
    dplyr::mutate(prop = n / sum(n)) %>% 
    janitor::add_totals_row() %>% 
    dplyr::mutate(prop = scales::percent(prop))
  if (kable) knitr::kable(tab) else tab
}

tabela_sum <- function(d, ..., n = 10, kable = TRUE) {
  l <- list(...)
  # print(l)
  soma <- function(x, na_rm = TRUE) {
    if (is.character(x)) {
      dplyr::n_distinct(x)
    } else {
      sum(x, na.rm = na_rm)
    }
  }
  s <- as.formula(glue::glue('~soma({l$v1})'))
  renm <- setNames('val', l$lab)
  tab <- d %>% 
    dplyr::filter_(l$f) %>% 
    dplyr::group_by_(.dots = unlist(stringr::str_split(l$v2, ', *'))) %>% 
    dplyr::summarise_(val = s) %>% 
    dplyr::ungroup() %>% 
    dplyr::arrange(dplyr::desc(val)) %>% 
    dplyr::rename_(.dots = renm) %>% 
    head(n)
  if (kable) knitr::kable(tab) else tab
}


create_vis <- function(d, cruzamentos) {
  tab <- cruzamentos %>% 
    dplyr::slice(16) %>%
    dplyr::group_by(relatorio, unidade, filtro, tipo, v1, v2, v3, lab) %>% 
    dplyr::do(res = {
      dplyr::failwith('erro', function(.) {
        eval(call(.$tipo, 
                  d = d, 
                  id = .$unidade, 
                  f = .$filtro,
                  v1 = .$v1,
                  v2 = .$v2,
                  v3 = .$v3,
                  lab = .$lab))
      })(.)
    }) %>% 
    dplyr::ungroup()
}

create_map <- function(d, var, map, denominador = 'pop',
                       fun = function(x) sum(!is.na(x))) {
  suppressWarnings({
    
    contas <- d %>%
      mutate(um = 1) %>% 
      mutate(id = uf_processo) %>%
      inner_join(pnud_uf, 'id') %>% 
      rename_(pop = if_else(denominador == 'pop', 'popt', 
                            if_else(denominador == 'n_muni', 'n_muni', 'um')))
    
    cortar <- function(x) {
      br <- unique(c(0, round(quantile(x, 0:4 / 4), 2)))
      cut(round(x, 2), breaks = br, 
          dig.lab = 10, 
          include.lowest = TRUE)
    }
    
    make_lab <- function(var, denominador, id, den, pop, labn, nn, razao) {
      if (str_detect(var, '^vl_') & denominador == 'um') {
        sprintf("<strong>UF</strong>: %s<br/>
                 <strong>Valor</strong>: %s<br/>",
                id, scales::dollar(nn))
      } else {
        sprintf("<strong>UF</strong>: %s<br/>
                 <strong>%s</strong>: %s<br/>
                 <strong>%s</strong>: %s<br/>
                 <strong>Razão</strong>: %s",
                id, 
                den, format(pop, big.mark = '.', decimal.mark = ','), 
                labn, 
                if_else(rep(str_detect(var, '^vl_'), length(nn)), 
                        scales::dollar(nn), 
                        as.character(round(nn))), 
                round(razao, 2))
      }
    }
    
    den <- if_else(denominador != 'n_muni', 'População', 'Qtd. Municípios')
    mult <- if_else(denominador == 'pop', 1e5, 1.0)
    var2 <- if_else(var == 'um', 'Condenações <br/>/ 100.000 Hab.',
                    str_to_title(str_replace_all(var, '_+', ' ')))
    if (denominador == 'n_muni') {
      var2 <- 'Condenações <br/>/ Município'
    }
    labn <- 'Condenações'
    if (str_detect(var, '^vl_')) labn <- 'Valor'
    
    labs <- contas %>% 
      arrange(id) %>% 
      group_by(id) %>% 
      summarise_at(vars(one_of(var)),
                   funs(nn = fun(.), pop = first(pop), razao = nn / pop * mult)) %>% 
      mutate(lab = make_lab(var, denominador, id, den, pop, labn, nn, razao)) %>% 
      mutate(razao = cortar(razao)) %>% 
      mutate(lab = purrr::map(lab, htmltools::HTML)) %>% 
      select(id, nn, razao, lab)
    labs[[var]] <- labs[['razao']]
    
    map@data %<>% inner_join(labs, c('name' = 'id'))
    
    pal <- colorFactor('YlOrRd', NULL)
    fpal <- as.formula(glue::glue('~pal({var})'))
    leaflet(map) %>%
      addTiles() %>% 
      addPolygons(fillColor = fpal,
                  color = 'black',
                  fillOpacity = 0.6,
                  weight = 2,
                  label = map@data$lab,
                  labelOptions = labelOptions(
                    style = list("font-weight" = "normal", 
                                 padding = "3px 8px"),
                    textsize = "15px",
                    direction = "auto"
                  )) %>% 
      addLegend(pal = pal, 
                title = var2,
                values = as.formula(paste0('~', var)),
                position = 'bottomright')
  })
}


# tabela multidimensional

# ggplot uni

# ggplot multi


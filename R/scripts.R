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

print_var('esfera_processo')
print_var('instancia')



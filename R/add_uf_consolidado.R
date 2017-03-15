library(purrr)

joga_resto_no_outros <- function(string, N, labell = 'outros'){
  
  d <- data_frame(coluna = string)
  
  left_join(d, y = d %>% count(coluna), by = 'coluna') %>% 
    mutate(coluna = ifelse(n < N, labell, coluna)) %>% 
    with(coluna)
}

lista_de_regex <- list(regex_pe = regex("pernambuco", ignore_case = T),
                       regex_pr = regex("paran[áa]", ignore_case = T),
                       regex_ba = regex("bahia", ignore_case = T),
                       regex_ce = regex("cear[áa]", ignore_case = T),
                       regex_pb = regex("para[íi]ba", ignore_case = T),
                       regex_rs = regex("rio grande do sul", ignore_case = T),
                       regex_go = regex("goi[áa]s", ignore_case = T),
                       regex_se = regex("sergipe", ignore_case  = T),
                       regex_ma = regex("maranhão", ignore_case = T),
                       regex_pa = regex("par[áa]($|[^a-zíóúéáôêâ])", ignore_case = T),
                       regex_rj = regex("rio de janeiro", ignore_case = T),
                       regex_es = regex("esp[íi]rito santo", ignore_case = T),
                       regex_to = regex("tocantins", ignore_case = T),
                       regex_rn = regex("rio grande do norte", ignore_case = T),
                       regex_sp = regex("s[ãa]o paulo", ignore_case = T),
                       regex_al = regex("alagoas", ignore_case = T),
                       regex_mg = regex("minas gerais", ignore_case = T),
                       regex_am = regex("amazonas", ignore_case = T),
                       regex_rr = regex("roraima", ignore_case = T),
                       regex_ro = regex("rond[ôo]nia", ignore_case = T),
                       regex_to = regex("tocantins", ignore_case = T),
                       regex_pi = regex("piau[íi]", ignore_case = T),
                       regex_ac = regex("acre", ignore_case = T),
                       regex_ms = regex("mato grosso do sul", ignore_case = T),
                       regex_mt = regex("mato grosso", ignore_case = T),
                       regex_ap = regex("amap[á]", ignore_case = T))

troca_string_por_regex <- function(vetor, regexes){
  map_chr(vetor, function(x){
    pareamentos <- map(regexes, str_detect, string = x) %>% 
      keep(~.x) %>% 
      names %>% 
      paste(collapse = ', ')
    
    if(pareamentos == ''){pareamentos <- x}
    return(pareamentos)
  })}

tidy_improb <- tidy_improb %>% 
  ungroup() %>% 
  mutate(uf_processo2 = troca_string_por_regex(comarca_secao, lista_de_regex),
         uf_processo2 = str_replace_all(uf_processo2, "regex_", ""),
         uf_processo3 = ifelse(str_detect(uf_processo2, "^[a-z]{2}$"), uf_processo2, as.character(NA)),
         uf_processo_consolidado = str_to_upper(ifelse(is.na(uf_processo), uf_processo3, uf_processo)))

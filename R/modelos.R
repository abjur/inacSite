library(lme4)
library(dplyr)
library(forcats)
library(rstanarm)
library(purrr)
library(lubridate)
library(mgcv)
library(stringr)

# joga_resto_no_outros <- function(string, N, labell = 'outros'){
#   
#   d <- data_frame(coluna = string)
#   
#   left_join(d, y = d %>% count(coluna), by = 'coluna') %>%
#     mutate(coluna = ifelse(n < N, labell, coluna)) %>%
#     with(coluna)
# }
# 
# lista_de_regex <- list(regex_roubo = regex("roubo", ignore_case = T),
#                        regex_homicidio = regex("homic[íi]dio|Crimes conta a vida", ignore_case = T),
#                        regex_estupro = regex("estupro|dignidade sexual", ignore_case = T),
#                        regex_trafico = regex("tr[áa]fico", ignore_case = T),
#                        regex_quadrila = regex("quadrilha", ignore_case = T),
#                        regex_chaci = regex("Adulteração de Sinal Identificador de Veículo", ignore_case = T),
#                        regex_receptacao = regex("Receptação", ignore_case = T),
#                        regex_furto = regex("Furto", ignore_case  = T),
#                        regex_patrimonio = regex("Crimes contra o Patrimônio|Crimes contra a Ordem Tributária|Crimes Praticados por Particular Contra a Administração em Geral|Crimes Praticados por Funcionários Públicos Contra a Administração em Geral|Crimes Praticados por Particular Contra a Administração Pública Estrangeira|Crimes contra a Economia Popular|Crimes Contra as Finanças Públicas|Crimes previstos na legislação extravagante", ignore_case = T))
# 
# troca_string_por_regex <- function(vetor, regexes){
#   map_chr(vetor, function(x){
#     pareamentos <- map(regexes, str_detect, string = x) %>%
#       keep(~.x) %>%
#       names %>%
#       paste(collapse = ', ')
#     
#     if(pareamentos == ''){pareamentos <- x}
#     return(pareamentos)
#   })}

data_to_fit <- tidy_improb %>%
  select(esfera_processo, dplyr::contains("teve_"), tipo_pessoa, n_processo, uf_processo_consolidado, dt_pena, assunto_nm_1) %>%
  filter(esfera_processo == "Estadual"|esfera_processo == "Federal") %>%
  mutate(assunto_nm_1 = fct_lump(assunto_nm_1, prop = 0.05, other_level = "Outros") %>% 
           str_to_title()) %>%
  mutate_if(function(x){!is.Date(x)},funs(as.factor(.))) %>% 
  rename(uf_processo = uf_processo_consolidado)

data_to_fit <- data_to_fit %>%
  mutate(uf_processo = fct_relevel(uf_processo, "SP")) %>%
  mutate_if(function(x){!is.Date(x)},funs(fct_relevel(., "FALSE"))) %>%
  filter(year(dt_pena) >= 2008) %>%
  mutate(ano = factor(year(dt_pena)))

data_to_fit$dt_pena <- as.numeric(data_to_fit$dt_pena)

ajusta <- function(yvar, xvar, inter, dataset, method = 'meanfield'){
  
  x <- paste(xvar, collapse = "+")
  
  if(missing(inter)){
    fun <- formula(paste0(yvar,"~",x))
  } else {
    fun <- formula(paste0(yvar,"~",x," + ",inter))
  }
  
  invisible(stan_glm(fun, family = binomial(link = 'logit'),
           data = data_to_fit, algorithm = method, verbose = F))
}

probability_map <- function(response_var, model_list){
  
  titulo <- str_extract(response_var, "[a-z]+$") %>% 
    str_to_title() %>% 
    paste("Mapa da probabilidade de",.)
  
  tidy_model <- model_list[[response_var]] %>% 
    broom::tidy() %>%
    mutate(term = str_replace_all(term,"uf_processo",""),
           id = 1:n(),
           base = ifelse(id == 1, estimate[1], estimate+estimate[1]),
           prob = exp(base)/(1+exp(base)),
           term = ifelse(term == "(Intercept)","SP",term),
           id = term) %>%
    filter(str_detect(term,"^[A-Z]{2}$")) %>%
    select(id, prob)
  
  tidy_model %>%
    inner_join(br_uf_map, by = 'id') %>% {
      ggplot(.) +
        geom_map(aes(x = long, y = lat, map_id = id, fill = prob),
                 color = 'gray30', map = ., data = .) +
        scale_fill_distiller(palette = 'YlOrRd', name = "Probabilidade base") +
        ggtitle(titulo) +
        coord_equal() +
        theme_void()
    }
}

# data_to_fit %>%
#   dplyr::filter(!is.na(uf_processo),!is.na(tipo_pena),!is.na(ano),
#                 !is.na(esfera_processo),!is.na(tem_jur)) %>%
#   mutate(lin_pred = fit2$linear.predictors,
#          prob = exp(lin_pred)/(1+exp(lin_pred)),
#          id = uf_processo) %>%
#   group_by(id) %>%
#   summarise(prob = mean(prob)) %>%
#   inner_join(br_uf_map, by = 'id') %>% {
#     ggplot(.) +
#       geom_map(aes(x = long, y = lat, map_id = id, fill = prob), color = 'gray30', map = ., data = .) +
#       coord_equal() +
#       theme_void()
#   }

response_vars <- names(data_to_fit) %>%
  str_subset("teve_[^(ress)]")

xvar <- c('1',"tipo_pessoa","esfera_processo","uf_processo","assunto_nm_1")

modelos <- map(response_vars, ajusta, xvar = xvar, dataset = data_to_fit,
               method = 'optimizing')

names(modelos) <- response_vars

ajustes <- modelos %>%
  map2_df(response_vars,~mutate(broom::tidy(.x), modelo = .y))

#
# stan_glm(teve_multa ~ 1 + tem_jur + tipo_pena:assunto_penal_any +
#            esfera_processo + uf_processo + assunto_penal_any +
#            tipo_pena, data = data_to_fit, algorithm = 'meanfield',
#          family = binomial('logit'))

probabilidades_por_estado <- map(response_vars, probability_map,
                                 model_list = modelos)

names(probabilidades_por_estado) = response_vars

proportion_map <- function(...){
  tidy_improb %>% 
    group_by(uf_processo_consolidado) %>% 
    summarise(...) %>% 
    rename(id = uf_processo_consolidado) %>% 
    inner_join(br_uf_map) %>% {
      ggplot(.) +
        geom_map(aes(x = long, y = lat, map_id = id, fill = prop), color = 'gray30', map = ., data = .) +
        scale_fill_distiller(palette = 'YlOrRd') + 
        coord_equal() +
        theme_void()
    }}
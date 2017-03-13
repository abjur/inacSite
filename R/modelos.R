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
  mutate_if(function(x){!is.Date(x)},funs(as.factor(.)))

data_to_fit <- data_to_fit %>%
  mutate(tipo_pena = fct_relevel(tipo_pena, "Órgão colegiado"),
         uf_processo = fct_relevel(uf_processo, "SP")) %>%
  mutate_if(function(x){!is.Date(x)},funs(fct_relevel(., "FALSE"))) %>%
  filter(year(dt_pena) >= 2008) %>%
  mutate(ano = factor(year(dt_pena)))

data_to_fit$dt_pena <- as.numeric(data_to_fit$dt_pena)

ajusta <- function(yvar, xvar, inter, dataset, method = 'meanfield'){
  
  x <- paste(xvar, collapse = "+")
  
  fun <- formula(paste0(yvar,"~",x," + ",inter))
  
  stan_glm(fun, family = binomial(link = 'logit'),
           data = data_to_fit, algorithm = method)
}

tidy_model <- broom::tidy(fit2) %>%
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
      geom_map(aes(x = long, y = lat, map_id = id, fill = prob), color = 'gray30', map = ., data = .) +
      coord_equal() +
      theme_void()
  }

data_to_fit %>%
  dplyr::filter(!is.na(uf_processo),!is.na(tipo_pena),!is.na(ano),
                !is.na(esfera_processo),!is.na(tem_jur)) %>%
  mutate(lin_pred = fit2$linear.predictors,
         prob = exp(lin_pred)/(1+exp(lin_pred)),
         id = uf_processo) %>%
  group_by(id) %>%
  summarise(prob = mean(prob)) %>%
  inner_join(br_uf_map, by = 'id') %>% {
    ggplot(.) +
      geom_map(aes(x = long, y = lat, map_id = id, fill = prob), color = 'gray30', map = ., data = .) +
      coord_equal() +
      theme_void()
  }

response_vars <- names(data_to_fit) %>%
  str_subset("teve_")

xvar <- c('1',"tipo_pena", "instancia","assunto_penal_any","tem_jur",
          "esfera_processo","uf_processo","ano")
inter <- c('tipo_pena:assunto_penal_any')

modelos <- map(response_vars, ajusta, xvar = xvar, dataset = data_to_fit,
               inter = inter, method = 'optimizing')

names(modelos) <- response_vars
#
# stan_glm(teve_multa ~ 1 + tem_jur + tipo_pena:assunto_penal_any +
#            esfera_processo + uf_processo + assunto_penal_any +
#            tipo_pena, data = data_to_fit, algorithm = 'meanfield',
#          family = binomial('logit'))

ajustes <- modelos %>%
  map2_df(response_vars,~mutate(broom::tidy(.x), modelo = .y))

###############################################################################
# DASHBOARDS
###############################################################################

# rmd <- 'content/dashboard/index.Rmd'
# ufs <- c("AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO", "MA", 
#          "MG", "MS", "MT", "PA", "PB", "PE", "PI", "PR", "RJ", "RN", "RO", 
#          "RR", "RS", "SC", "SE", "SP", "TO")
# regioes <- c('', "Centro-Oeste", "Nordeste", "Norte", "Sudeste", "Sul")
# # ufs <- head(ufs)
# cats <- regioes
# params <- purrr::map(cats, ~setNames(list(.x), 'regiao'))
# nms <- glue::glue('index_{regioes}.html')
# 
# dir_backup <- getwd()
# setwd(dirname(rmd))
# purrr::walk2(params, nms, ~rmarkdown::render(
#   input = basename(rmd),
#   output_format = rmarkdown::html_document(
#     theme = NULL,
#     self_contained = FALSE
#   ),
#   output_file = .y, params = .x, 
#   quiet = TRUE)
# )
# setwd(dir_backup)

###
library(magrittr)
rmd <- 'content/dashboard/template.Rmd'
ufs <- c("AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO", "MA", 
         "MG", "MS", "MT", "PA", "PB", "PE", "PI", "PR", "RJ", "RN", "RO", 
         "RR", "RS", "SC", "SE", "SP", "TO")
regioes <- c('', "Centro-Oeste", "Nordeste", "Norte", "Sudeste", "Sul")
esferas <- c('', "Estadual", "Federal")

# ufs <- head(ufs)
params <- purrr::cross_n(list(regiao = regioes, 
                              uf = NA_character_,
                              esfera_processo = esferas))

nms <- purrr::map_chr(params, ~{
  ._1 <- ifelse(.x$regiao == '', '', '_')
  ._2 <- ifelse(.x$esfera_processo == '', '', '_')
  glue::glue('index{._1}{.x$regiao}{._2}{.x$esfera_processo}.Rmd')
})
  
txt <- 'list(uf = NA, regiao = NA, esfera_processo = NA)'
purrr::walk2(params, nms, ~{
  l <- stringr::str_replace(readr::read_file(rmd), 
                            stringr::fixed(txt), 
                            deparse(.x, width.cutoff = 200))
  ff <- glue::glue("{dirname(rmd)}/{.y}")
  cat(l, file = ff)
  # old_wd <- getwd()
  # setwd(dirname(rmd))
  # rmarkdown::render(ff)
  # setwd(old_wd)
})
### 


###############################################################################
# HISTORIAS
###############################################################################

rmds <- dir("content/historias", pattern = "\\.Rmd$", full.names = T) 

for(rmd in rmds) {
  rmarkdown::render(rmd, output_format = rmarkdown::md_document(
    variant = 'markdown', preserve_yaml = F, pandoc_args = '--mathjax'), 
    clean = F, quiet = T)
  rmd_lines <- rmd %>%
    readLines()
  md <- gsub("\\.Rmd","\\.md",rmd) %>%
    readLines()
  yaml_pos <- rmd_lines %>%
    stringr::str_detect("---") %>%
    which()
  yaml <- rmd_lines[yaml_pos[1]:yaml_pos[2]]
  md_non_yaml <- md %>% 
    stringr::str_detect("^---$") %>% 
    which() %>% 
    max()
  md <- md %>% 
    stringr::str_replace_all(" \\{.+\\}","")
  #md[yaml_pos[1]:yaml_pos[2]] <- yaml
  bookdown:::writeUTF8(c(yaml, md[(md_non_yaml+1):length(md)]), 
                       gsub("\\.Rmd", "\\.md", rmd))
}

rejects <- list.files("content/historias", 
                      pattern = 'knit|utf8', 
                      full.names = T)
file.remove(rejects)


###############################################################################
# HUGO
###############################################################################

blogdown:::hugo_build()

files2copy <- dir('content/historias', pattern = 'files', full.names = T) %>%
  setdiff(rejects)
dir_folder <- gsub("content/", "public/", files2copy) %>%
  gsub("_files(/)?", "/", .)
for(i in seq_along(dir_folder)) {
  dir.create(dir_folder[i], recursive = TRUE, showWarnings = FALSE)
  file.copy(files2copy[i], dir_folder[i], recursive = TRUE)
}

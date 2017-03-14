blogdown::install_hugo(version = "0.19")

rmd <- 'content/dashboard/index.Rmd'
ufs <- c("AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO", "MA", 
         "MG", "MS", "MT", "PA", "PB", "PE", "PI", "PR", "RJ", "RN", "RO", 
         "RR", "RS", "SC", "SE", "SP", "TO")
# ufs <- head(ufs)
nms <- glue::glue('index_{ufs}.Rmd')
dir_backup <- getwd()
setwd(dirname(rmd))
purrr::walk2(ufs, nms, ~rmarkdown::render(
  input = basename(rmd),
  output_format = rmarkdown::md_document(preserve_yaml = TRUE),
  output_file = .y, params = list(uf = .x), 
  quiet = TRUE)
)
setwd(dir_backup)

blogdown::build_site()

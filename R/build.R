library(magrittr)

rmds <- list.files("content/historias", pattern = "\\.Rmd$", full.names = T) 

for(rmd in rmds){
  rmarkdown::render(rmd, output_format = rmarkdown::md_document(
    variant = 'markdown', preserve_yaml = F, pandoc_args = '--mathjax'), clean = F)
  
  rmd_lines <- rmd %>%
    readLines()
  
  md <- gsub("\\.Rmd","\\.md",rmd) %>%
    readLines()
  
  yaml_pos <- rmd_lines %>%
    stringr::str_detect("---") %>%
    which
  
  yaml <- rmd_lines[yaml_pos[1]:yaml_pos[2]]
  
  md_non_yaml <- md %>% 
    stringr::str_detect("^---$") %>% 
    which %>% 
    max
  
  md <- md %>% 
    stringr::str_replace_all(" \\{.+\\}","")
  
  #md[yaml_pos[1]:yaml_pos[2]] <- yaml
  
  bookdown:::writeUTF8(c(yaml, md[(md_non_yaml+1):length(md)]), gsub("\\.Rmd","\\.md",rmd))
}

rejects <- list.files("content/historias", pattern = 'knit|utf8', full.names = T)
file.remove(rejects)

blogdown::install_hugo(version = "0.18")
blogdown:::hugo_build()

files2copy <- list.files('content/historias', pattern = 'files', full.names = T) %>%
  setdiff(rejects)

dir_folder <- gsub("content/","public/", files2copy) %>%
  gsub("_files(/)?","/",.)

for(i in seq_along(dir_folder)){
  file.copy(files2copy[i], dir_folder[i], recursive = T)
}

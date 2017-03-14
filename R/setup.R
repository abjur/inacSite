# Cruzamentos -----------------------------------------------------------------
cruzamentos <- tibble::tribble(
  ~relatorio, ~unidade, ~filtro, ~tipo, ~v1, ~v2, ~v3, ~lab, 
  # perfil unidimensional
  'pessoa', 'id_pessoa', "TRUE", 'tabela', 'publico', NA, NA, '',
  'pessoa', 'id_pessoa', "TRUE", 'tabela', 'sexo', NA, NA, '',
  'pessoa', 'id_pessoa', "TRUE", 'tabela', 'tipo_pessoa', NA, NA, '',
  'pessoa', 'id_pessoa', "tipo_pessoa=='J'", 'tabela', 'esfera', NA, NA, '',
  'pessoa', 'id_pessoa', "tipo_pessoa=='J'", 'tabela', 'orgao', NA, NA, '',
  # rankings
  'pessoa', 'id_pessoa', "TRUE", 
  'tabela_sum', 'id_processo', 'id_pessoa,nm_pessoa', NA, 'val',
  
  'pessoa', 'id_pessoa', "TRUE", 
  'tabela_sum', 'vl_ressarcimento', 'id_pessoa,nm_pessoa', NA, 'val',
  
  'pessoa', 'id_pessoa', "TRUE", 
  'tabela_sum', 'vl_multa', 'id_pessoa,nm_pessoa', NA, 'val',
  
  'pessoa', 'id_pessoa', "TRUE", 
  'tabela_sum', 'tempo_processo', 'id_pessoa,nm_pessoa', NA, 'val',
  
  # rankings de teve_x
  'pessoa', 'id_pessoa', "TRUE", 
  'tabela_sum', 'teve_inelegivel', 'id_pessoa,nm_pessoa', NA, 'val',
  
  'pessoa', 'id_pessoa', "TRUE", 
  'tabela_sum', 'teve_multa', 'id_pessoa,nm_pessoa', NA, 'val',
  
  'pessoa', 'id_pessoa', "TRUE", 
  'tabela_sum', 'teve_pena', 'id_pessoa,nm_pessoa', NA, 'val',
  
  'pessoa', 'id_pessoa', "TRUE", 
  'tabela_sum', 'teve_perda_bens', 'id_pessoa,nm_pessoa', NA, 'val',
  
  'pessoa', 'id_pessoa', "TRUE", 
  'tabela_sum', 'teve_perda_cargo', 'id_pessoa,nm_pessoa', NA, 'val',
  
  'pessoa', 'id_pessoa', "TRUE", 
  'tabela_sum', 'teve_proibicao', 'id_pessoa,nm_pessoa', NA, 'val',
  
  'pessoa', 'id_pessoa', "TRUE", 
  'tabela_sum', 'teve_ressarcimento', 'id_pessoa,nm_pessoa', NA, 'val',
  
  'pessoa', 'id_pessoa', "TRUE", 
  'tabela_sum', 'teve_suspensao', 'id_pessoa,nm_pessoa', NA,  'val'
)

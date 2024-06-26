-- 1 limpando tabela
DELETE FROM engajamento_mentorias;

   
-- 2 colocando os dados das tabelas produto_mdl e telemetria_plataforma
   INSERT INTO engajamento_mentorias (email_user, fase_atual, datacarga_timeevent, titulo, pageid, cliente_mdl, nome_curso)
SELECT 
    pm.email_do_cliente, 
    pm.fase_atual, 
    pm.data_carga, 
    pm.titulo, 
    tp."pageId", 
    tp."cliente_MDL", 
    tp.nome_curso
FROM 
    produto_mdl AS pm
LEFT JOIN 
    telemetria_plataforma AS tp 
ON 
    pm.data_carga = tp.timestamp_evento 
    AND pm.email_do_cliente = tp."user" 
    AND (tp."cliente_MDL" = 'evento_MDL' OR tp."cliente_MDL" = '');
   
-- 3 gerando chave primária  
   ALTER TABLE engajamento_mentorias
ADD COLUMN id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY;

-- 4 deletando dados duplicados
WITH RankedDupes AS (
  SELECT
    em.id, -- Substitua 'primary_key_column' pela coluna de chave primária ou um identificador único.
    ROW_NUMBER() OVER (
      PARTITION BY email_user, fase_atual, datacarga_timeevent, titulo, pageid, cliente_mdl, nome_curso
      ORDER BY datacarga_timeevent -- Ou substitua por um critério de ordenação, se necessário.
    ) AS rn
  from engajamento_mentorias em
)
DELETE FROM engajamento_mentorias
WHERE id IN (
  SELECT id FROM RankedDupes WHERE rn > 1
);

   
   
   
-- Criando a trigger 


-- 1 criando a função (1)
CREATE OR REPLACE FUNCTION limpar_tabela_em 
RETURNS TRIGGER AS $$
BEGIN
         DELETE FROM engajamento_mentorias;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 1 criando o gatilho da função (1)

create trigger trigger_limpar_tabela_em
after insert on produto_mdl	
for each row 
execute  function limpar_tabela_em;


-- 2 criando a função (2)
CREATE OR REPLACE FUNCTION inserir_dados_na_em 
RETURNS TRIGGER AS $$
BEGIN
         INSERT INTO engajamento_mentorias (email_user, fase_atual, datacarga_timeevent, titulo, pageid, cliente_mdl, nome_curso)
SELECT 
    pm.email_do_cliente, 
    pm.fase_atual, 
    pm.data_carga, 
    pm.titulo, 
    tp."pageId", 
    tp."cliente_MDL", 
    tp.nome_curso
FROM 
    produto_mdl AS pm
LEFT JOIN 
    telemetria_plataforma AS tp 
ON 
    pm.data_carga = tp.timestamp_evento 
    AND pm.email_do_cliente = tp."user" 
    AND (tp."cliente_MDL" = 'evento_MDL' OR tp."cliente_MDL" = '');
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 2 criando o gatilho da função (2)

create trigger trigger_inserir_dados_na_em
after delete on engajamento_mentorias
for each row 
execute  function inserir_dados_na_em;



-- 3 criando a função (3)
CREATE OR REPLACE FUNCTION chave_primaria_em 
RETURNS TRIGGER AS $$
BEGIN
         ALTER TABLE engajamento_mentorias
ADD COLUMN id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY;;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
   

-- 3 criando o gatilho da função (3)

create trigger trigger_chave_primaria_em
after insert on engajamento_mentorias
for each row 
execute  function chave_primaria_em;



-- 4 criando a função (4)
CREATE OR REPLACE FUNCTION limpando_duplicadas_em 
RETURNS TRIGGER AS $$
BEGIN
         WITH RankedDupes AS (
  SELECT
    em.id, -- Substitua 'primary_key_column' pela coluna de chave primária ou um identificador único.
    ROW_NUMBER() OVER (
      PARTITION BY email_user, fase_atual, datacarga_timeevent, titulo, pageid, cliente_mdl, nome_curso
      ORDER BY datacarga_timeevent -- Ou substitua por um critério de ordenação, se necessário.
    ) AS rn
  from engajamento_mentorias em
)
DELETE FROM engajamento_mentorias
WHERE id IN (
  SELECT id FROM RankedDupes WHERE rn > 1
);
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- 4 criando o gatilho da função (4)

create trigger trigger_limpando_duplicadas_em
after update on engajamento_mentorias
for each row 
execute  function limpando_duplicadas_em;

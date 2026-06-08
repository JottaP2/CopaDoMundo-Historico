-- 01 Contra quais adversários o Brasil mais sofreu derrotas em Copas do Mundo, ordenados do máximo ao mínimo de vezes?
SELECT 
    CASE 
        WHEN p.abrev_time_casa = 'BRA' THEN s_vis.nome_selecao
        ELSE s_casa.nome_selecao
    END AS nome_adversario,
    COUNT(p.partida_id) AS total_confrontos,
    SUM(
        CASE 
            WHEN p.abrev_time_casa = 'BRA' AND p.gols_casa < p.gols_visitante THEN 1
            WHEN p.abrev_time_visitante = 'BRA' AND p.gols_visitante < p.gols_casa THEN 1
            ELSE 0
        END
    ) AS total_derrotas_brasil,
    SUM(
        CASE 
            WHEN p.abrev_time_casa = 'BRA' AND p.gols_casa > p.gols_visitante THEN 1
            WHEN p.abrev_time_visitante = 'BRA' AND p.gols_visitante > p.gols_casa THEN 1
            ELSE 0
        END
    ) AS total_vitorias_brasil
FROM tb_partida p
JOIN tb_selecao s_casa ON p.abrev_time_casa = s_casa.abrev_selecao
JOIN tb_selecao s_vis ON p.abrev_time_visitante = s_vis.abrev_selecao
WHERE p.abrev_time_casa = 'BRA' OR p.abrev_time_visitante = 'BRA'
GROUP BY nome_adversario
HAVING total_derrotas_brasil > 0
ORDER BY total_derrotas_brasil DESC, total_vitorias_brasil ASC;

-- 02 Qual país tem mais gols em copa em toda a história ?
SELECT 
    s.nome_selecao,
    SUM(
        CASE 
            WHEN p.abrev_time_casa = s.abrev_selecao THEN p.gols_casa
            WHEN p.abrev_time_visitante = s.abrev_selecao THEN p.gols_visitante
            ELSE 0
        END
    ) AS total_gols_marcados
FROM tb_partida p
JOIN tb_selecao s ON p.abrev_time_casa = s.abrev_selecao OR p.abrev_time_visitante = s.abrev_selecao
GROUP BY s.nome_selecao
ORDER BY total_gols_marcados DESC
LIMIT 5;

-- 03 - Quais seleções chegaram na copa mas nunca conseguiram chegar a fase de semi-final ou final ?
SELECT DISTINCT 
    s.nome_selecao,
    s.abrev_selecao
FROM tb_selecao s
LEFT JOIN tb_copa c ON s.abrev_selecao = c.abrev_campeao 
                    OR s.abrev_selecao = c.abrev_vice
                    OR s.abrev_selecao = c.abrev_terceiro
                    OR s.abrev_selecao = c.abrev_quarto
WHERE c.ano IS NULL
ORDER BY s.nome_selecao ASC;

-- 04 Qual edição registou a maior média histórica de golos por partida e qual foi esse valor?
SELECT 
    ano,
    pais_sede,
    qtd_gols,
    partidas_jogadas,
    ROUND((qtd_gols * 1.0 / partidas_jogadas), 2) AS media_golos_por_jogo
FROM tb_copa
ORDER BY media_golos_por_jogo DESC
LIMIT 1;


-- 05 Quais estádios registraram os maiores desniveis técnicos sobre saldo de gol em jogos do mata-mata? (coloquei na maldade essa só para ver se o 7x1 era a maior kkk).
SELECT 
    e.nome_estadio,
    MAX(ABS(p.gols_casa - p.gols_visitante)) AS maior_goleada_registrada,
    COUNT(p.partida_id) AS total_partidas_fase
FROM tb_partida p
JOIN tb_estadio e ON p.id_estadio = e.id_estadio
WHERE p.fase NOT LIKE 'Group%'
GROUP BY e.nome_estadio
ORDER BY maior_goleada_registrada DESC
LIMIT 5;

-- 06 Em anos que o Brasil foi campeão, quem foi o primeiro e o último jogador a marca pela seleção?
WITH partidas_brasil AS (
    SELECT 
        p.ano_copa,
        p.partida_id,
        p.data_hora,
        p.abrev_time_casa,
        p.abrev_time_visitante
    FROM tb_partida p
    JOIN tb_copa c ON p.ano_copa = c.ano
    WHERE c.abrev_campeao = 'BRA' 
      AND (p.abrev_time_casa = 'BRA' OR p.abrev_time_visitante = 'BRA')
),
gols_brasil AS (
    SELECT 
        pb.ano_copa,
        pb.partida_id,
        pb.data_hora,
        j.nome_jogador,
        pj.eventos,
        ROW_NUMBER() OVER(PARTITION BY pb.ano_copa ORDER BY pb.data_hora ASC) AS ordem_jogo_asc,
        ROW_NUMBER() OVER(PARTITION BY pb.ano_copa ORDER BY pb.data_hora DESC) AS ordem_jogo_desc
    FROM tb_partida_jogador pj
    JOIN tb_jogador j ON pj.id_jogador = j.id_jogador
    JOIN partidas_brasil pb ON pj.partida_id = pb.partida_id
    WHERE pj.abrev_selecao = 'BRA' 
      AND pj.eventos LIKE '%G%'
),
primeiro_gol AS (
    SELECT ano_copa, nome_jogador AS primeiro_goleador
    FROM gols_brasil
    WHERE ordem_jogo_asc = 1
    GROUP BY ano_copa
),
ultimo_gol AS (
    SELECT ano_copa, nome_jogador AS ultimo_goleador
    FROM gols_brasil
    WHERE ordem_jogo_desc = 1
    GROUP BY ano_copa
)
SELECT 
    p.ano_copa AS ano_titulo,
    p.primeiro_goleador,
    u.ultimo_goleador
FROM primeiro_gol p
JOIN ultimo_gol u ON p.ano_copa = u.ano_copa
ORDER BY ano_titulo ASC;

-- 07 Total de participações das seleções em copas?

SELECT 
    s.nome_selecao,
    COUNT(DISTINCT p.ano_copa) AS total_participacoes
FROM tb_selecao s
JOIN tb_partida p ON s.abrev_selecao = p.abrev_time_casa OR s.abrev_selecao = p.abrev_time_visitante
GROUP BY s.nome_selecao
ORDER BY total_participacoes DESC;

-- 08 Sabemos que nem todas as seleções da copa são "boas", então qual foi o volume de gols nos 15 minutos iniciais da partida e após os 80minutos ?

SELECT 
    SUM(CASE WHEN eventos LIKE '%G1%' OR eventos LIKE '%G2%' OR eventos LIKE '%G3%' OR eventos LIKE '%G4%' OR eventos LIKE '%G5%' OR eventos LIKE '%G10%' OR eventos LIKE '%G11%' OR eventos LIKE '%G12%' OR eventos LIKE '%G13%' OR eventos LIKE '%G14%' OR eventos LIKE '%G15%' THEN 1 ELSE 0 END) AS gols_primeiros_15_min,
    SUM(CASE WHEN eventos LIKE '%G80%' OR eventos LIKE '%G81%' OR eventos LIKE '%G82%' OR eventos LIKE '%G83%' OR eventos LIKE '%G84%' OR eventos LIKE '%G85%' OR eventos LIKE '%G86%' OR eventos LIKE '%G87%' OR eventos LIKE '%G88%' OR eventos LIKE '%G89%' OR eventos LIKE '%G90%' THEN 1 ELSE 0 END) AS gols_finais_apos_80_min
FROM tb_partida_jogador
WHERE eventos LIKE '%G%';

-- 09 Quantas partidas registraram uma virada completa de placar no segundo tempo após uma das equipes ir para o vestiário vencendo a partida no intervalo?

SELECT 
    COUNT(partida_id) AS total_jogos_com_dados,
    SUM(CASE WHEN gols_tempo_reg_casa > gols_tempo_reg_visitante AND gols_casa < gols_visitante THEN 1 ELSE 0 END) AS viradas_sofridas_casa,
    SUM(CASE WHEN gols_tempo_reg_visitante > gols_tempo_reg_casa AND gols_visitante < gols_casa THEN 1 ELSE 0 END) AS viradas_sofridas_visitante
FROM tb_partida
WHERE gols_tempo_reg_casa IS NOT NULL;

-- 10 Quais finais de Copa do Mundo registraram o maior (recorde) e o pior (mínimo) público pagante da história?

WITH finais AS (
    SELECT 
        p.ano_copa,
        s_casa.nome_selecao AS time_casa,
        s_vis.nome_selecao AS time_visitante,
        p.gols_casa,
        p.gols_visitante,
        p.publico
    FROM tb_partida p
    JOIN tb_selecao s_casa ON p.abrev_time_casa = s_casa.abrev_selecao
    JOIN tb_selecao s_vis ON p.abrev_time_visitante = s_vis.abrev_selecao
    WHERE p.fase = 'Final' AND p.publico IS NOT NULL
)
SELECT 
    'MAIOR PÚBLICO (RECORDE)' AS tipo_registro,
    ano_copa,
    time_casa || ' ' || gols_casa || ' x ' || gols_visitante || ' ' || time_visitante AS confronto,
    publico
FROM finais
WHERE publico = (SELECT MAX(publico) FROM finais)

UNION ALL

SELECT 
    'PIOR PÚBLICO (MÍNIMO)' AS tipo_registro,
    ano_copa,
    time_casa || ' ' || gols_casa || ' x ' || gols_visitante || ' ' || time_visitante AS confronto,
    publico
FROM finais
WHERE publico = (SELECT MIN(publico) FROM finais);

-- 11 Quais jogadores marcaram o maior número total de gols somando todas as edições?

SELECT 
    j.nome_jogador,
    SUM(
        (LENGTH(pj.eventos) - LENGTH(REPLACE(pj.eventos, 'G', '')))
    ) AS total_gols_na_historia
FROM tb_partida_jogador pj
JOIN tb_jogador j ON pj.id_jogador = j.id_jogador
WHERE pj.eventos LIKE '%G%'
GROUP BY j.id_jogador, j.nome_jogador
ORDER BY total_gols_na_historia DESC
LIMIT 5;

-- 12 Qual jogador disputou o maior número de edições de Copas do Mundo por uma seleção?
SELECT 
    j.nome_jogador,
    s.nome_selecao,
    COUNT(DISTINCT p.ano_copa) AS total_copas_disputadas
FROM tb_partida_jogador pj
JOIN tb_jogador j ON pj.id_jogador = j.id_jogador
JOIN tb_partida p ON pj.partida_id = p.partida_id
JOIN tb_selecao s ON pj.abrev_selecao = s.abrev_selecao
GROUP BY j.id_jogador, j.nome_jogador, s.nome_selecao
ORDER BY total_copas_disputadas DESC
LIMIT 5;

-- 13 Quais seleções sofreram a menor média de gols por partida em uma única edição de Copa, considerando apenas equipes que chegaram pelo menos até a semifinal!

SELECT 
    p.ano_copa,
    s.nome_selecao,
    COUNT(p.partida_id) AS total_jogos_disputados,
    SUM(
        CASE 
            WHEN p.abrev_time_casa = s.abrev_selecao THEN p.gols_visitante
            ELSE p.gols_casa
        END
    ) AS total_gols_sofridos,
    ROUND(AVG(
        CASE 
            WHEN p.abrev_time_casa = s.abrev_selecao THEN p.gols_visitante
            ELSE p.gols_casa
        END
    ), 2) AS media_gols_sofridos_por_jogo
FROM tb_partida p
JOIN tb_selecao s ON p.abrev_time_casa = s.abrev_selecao OR p.abrev_time_visitante = s.abrev_selecao
JOIN tb_copa c ON p.ano_copa = c.ano
WHERE s.abrev_selecao IN (c.abrev_campeao, c.abrev_vice, c.abrev_terceiro, c.abrev_quarto)
GROUP BY p.ano_copa, s.nome_selecao
HAVING total_jogos_disputados >= 5
ORDER BY media_gols_sofridos_por_jogo ASC
LIMIT 10;

-- 14 Qual é o total acumulado de gols da história das Copas rodada a rodada, mostrando a evolução do volume de gols ao longo dos anos?

SELECT 
    ano,
    pais_sede,
    qtd_gols AS gols_da_edicao,
    SUM(qtd_gols) OVER (ORDER BY ano ASC) AS total_gols_acumulados_na_historia
FROM tb_copa
ORDER BY ano ASC;

-- 15 Quantas partidas o Rei Pelé disputou e quais eventos decisivos (gols/assistências) ficaram registrados no seu histórico?

SELECT 
    j.nome_jogador,
    COUNT(DISTINCT p.partida_id) AS total_partidas_em_copas,
    COUNT(DISTINCT p.ano_copa) AS edicoes_disputadas,
    SUM(
        (LENGTH(pj.eventos) - LENGTH(REPLACE(pj.eventos, 'G', '')))
    ) AS total_gols_registrados
FROM tb_partida_jogador pj
JOIN tb_jogador j ON pj.id_jogador = j.id_jogador
JOIN tb_partida p ON pj.partida_id = p.partida_id
WHERE j.nome_jogador = 'PEL� (Edson Arantes do Nascimento)'
GROUP BY j.id_jogador, j.nome_jogador;
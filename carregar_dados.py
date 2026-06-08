import os
import pandas as pd
import sqlite3

caminho_banco = r'c:\sqlite\fifawordcup-bd1-av1.db'

if not os.path.exists(caminho_banco):
    raise FileNotFoundError(
        f"O arquivo de banco de dados não foi encontrado em: {caminho_banco}\n"
        f"Certifique-se de que criou o banco com o DDL antes de rodar a carga."
    )
conn = sqlite3.connect(caminho_banco)
cursor = conn.cursor()

cursor.execute("PRAGMA foreign_keys = ON;")

print("Carregando arquivos CSV brutos...")
df_cups = pd.read_csv('dataset/WorldCups.csv')
df_matches = pd.read_csv('dataset/WorldCupMatches.csv')
df_players = pd.read_csv('dataset/WorldCupPlayers.csv')

df_matches = df_matches.dropna(subset=['MatchID'])
df_players = df_players.dropna(subset=['MatchID'])

df_matches['MatchID'] = df_matches['MatchID'].astype(int)
df_matches['RoundID'] = df_matches['RoundID'].astype(int)
df_players['MatchID'] = df_players['MatchID'].astype(int)

def limpa_texto(txt):
    if pd.isna(txt): return None
    return str(txt).strip()

print("Processando e inserindo as Seleções...")
selecoes = set()

for idx, row in df_matches.iterrows():
    c_name = limpa_texto(row['Home Team Name'])
    c_init = limpa_texto(row['Home Team Initials'])
    v_name = limpa_texto(row['Away Team Name'])
    v_init = limpa_texto(row['Away Team Initials'])
    if c_name and c_init: selecoes.add((c_init, c_name))
    if v_name and v_init: selecoes.add((v_init, v_name))

mapa_nomes_siglas = {name: init for init, name in selecoes}
mapa_nomes_siglas['Germany FR'] = 'FRG'
mapa_nomes_siglas['German DR'] = 'GDR'
mapa_nomes_siglas['Soviet Union'] = 'URS'
mapa_nomes_siglas['Zaire'] = 'ZAI'

selecoes.add(('FRG', 'Germany FR'))
selecoes.add(('GDR', 'German DR'))
selecoes.add(('URS', 'Soviet Union'))

for init, name in selecoes:
    cursor.execute("""
        INSERT OR IGNORE INTO tb_selecao (abrev_selecao, nome_selecao) 
        VALUES (?, ?);
    """, (init, name))
conn.commit()

print("Processando Cidades e Estádios...")
for idx, row in df_matches.iterrows():
    cidade = limpa_texto(row['City'])
    estadio = limpa_texto(row['Stadium'])
    if cidade:
        cursor.execute("INSERT OR IGNORE INTO tb_cidade (nome_cidade) VALUES (?);", (cidade,))
        cursor.execute("SELECT id_cidade FROM tb_cidade WHERE nome_cidade = ?;", (cidade,))
        id_cidade = cursor.fetchone()[0]
        if estadio:
            cursor.execute("""
                INSERT OR IGNORE INTO tb_estadio (nome_estadio, id_cidade) 
                VALUES (?, ?);
            """, (estadio, id_cidade))
conn.commit()

print("Processando Técnicos e Jogadores...")
for idx, row in df_players.iterrows():
    tecnico = limpa_texto(row['Coach Name'])
    jogador = limpa_texto(row['Player Name'])
    if tecnico:
        cursor.execute("INSERT OR IGNORE INTO tb_tecnico (nome_tecnico) VALUES (?);", (tecnico,))
    if jogador:
        cursor.execute("INSERT OR IGNORE INTO tb_jogador (nome_jogador) VALUES (?);", (jogador,))
conn.commit()

print("Mapeando e inserindo as Edições das Copas...")
for idx, row in df_cups.iterrows():
    att = str(row['Attendance']).replace('.', '') if not pd.isna(row['Attendance']) else None
    cursor.execute("""
        INSERT OR IGNORE INTO tb_copa 
        (ano, pais_sede, abrev_campeao, abrev_vice, abrev_terceiro, abrev_quarto, 
         qtd_gols, times_classificados, partidas_jogadas, publico_total)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """, (
        int(row['Year']),
        limpa_texto(row['Country']),
        mapa_nomes_siglas.get(limpa_texto(row['Winner'])),
        mapa_nomes_siglas.get(limpa_texto(row['Runners-Up'])),
        mapa_nomes_siglas.get(limpa_texto(row['Third'])),
        mapa_nomes_siglas.get(limpa_texto(row['Fourth'])),
        int(row['GoalsScored']),
        int(row['QualifiedTeams']),
        int(row['MatchesPlayed']),
        int(att) if att else None
    ))
conn.commit()

print("Processando os registros das Partidas...")
partidas_inseridas = set()
for idx, row in df_matches.iterrows():
    m_id = int(row['MatchID'])
    if m_id in partidas_inseridas: 
        continue
    
    cidade = limpa_texto(row['City'])
    estadio = limpa_texto(row['Stadium'])
    
    cursor.execute("""
        SELECT e.id_estadio FROM tb_estadio e 
        JOIN tb_cidade c ON e.id_cidade = c.id_cidade 
        WHERE e.nome_estadio = ? AND c.nome_cidade = ?;
    """, (estadio, cidade))
    res = cursor.fetchone()
    id_estadio = res[0] if res else 1
    
    publico = str(row['Attendance']).replace('.0', '') if not pd.isna(row['Attendance']) else None
    
    cursor.execute("""
        INSERT OR IGNORE INTO tb_partida 
        (partida_id, rodada_id, ano_copa, data_hora, fase, id_estadio, abrev_time_casa, abrev_time_visitante, 
         gols_casa, gols_visitante, publico, gols_tempo_reg_casa, gols_tempo_reg_visitante, condicoes_vitoria)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """, (
        m_id, int(row['RoundID']), int(row['Year']), limpa_texto(row['Datetime']), limpa_texto(row['Stage']), id_estadio,
        limpa_texto(row['Home Team Initials']), limpa_texto(row['Away Team Initials']), int(row['Home Team Goals']), int(row['Away Team Goals']),
        int(float(publico)) if publico and publico != 'nan' else None,
        int(row['Half-time Home Goals']) if not pd.isna(row['Half-time Home Goals']) else None,
        int(row['Half-time Away Goals']) if not pd.isna(row['Half-time Away Goals']) else None,
        limpa_texto(row['Win conditions'])
    ))
    partidas_inseridas.add(m_id)
conn.commit()

print("Gerando mapeamentos de escalações (Aguarde)...")
cursor.execute("SELECT id_jogador, nome_jogador FROM tb_jogador;")
mapa_jogadores = {nome: id_j for id_j, nome in cursor.fetchall()}

cursor.execute("SELECT id_tecnico, nome_tecnico FROM tb_tecnico;")
mapa_tecnicos = {nome: id_t for id_t, nome in cursor.fetchall()}

escalacoes_inseridas = set()
insert_buffer = []

for idx, row in df_players.iterrows():
    m_id = int(row['MatchID'])
    p_name = limpa_texto(row['Player Name'])
    c_name = limpa_texto(row['Coach Name'])
    
    id_jogador = mapa_jogadores.get(p_name)
    id_tecnico = mapa_tecnicos.get(c_name)
    
    if id_jogador and id_tecnico:
        chave_composta = (m_id, id_jogador)
        if chave_composta in escalacoes_inseridas: 
            continue
        
        camisa = int(row['Shirt Number']) if not pd.isna(row['Shirt Number']) else 0
        insert_buffer.append((
            m_id, id_jogador, limpa_texto(row['Team Initials']), id_tecnico, camisa,
            limpa_texto(row['Line-up']), limpa_texto(row['Position']), limpa_texto(row['Event'])
        ))
        escalacoes_inseridas.add(chave_composta)

print(f"Efetuando inserção em massa de {len(insert_buffer)} registros de atletas...")
cursor.executemany("""
    INSERT OR IGNORE INTO tb_partida_jogador 
    (partida_id, id_jogador, abrev_selecao, id_tecnico, numero_camisa, tipo_escalacao, posicao, eventos)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?);
""", insert_buffer)

conn.commit()
conn.close()
print(f"\n[SUCESSO] Carga concluída! Dados adicionados em: {caminho_banco}")

PRAGMA foreign_keys = ON;

CREATE TABLE tb_cidade (
    id_cidade INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_cidade TEXT NOT NULL UNIQUE
);

CREATE TABLE tb_estadio (
    id_estadio INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_estadio TEXT NOT NULL,
    id_cidade INTEGER NOT NULL,
    FOREIGN KEY (id_cidade) REFERENCES tb_cidade(id_cidade),
    UNIQUE(nome_estadio, id_cidade)
);

CREATE TABLE tb_selecao (
    abrev_selecao TEXT PRIMARY KEY,
    nome_selecao TEXT NOT NULL UNIQUE
);

CREATE TABLE tb_jogador (
    id_jogador INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_jogador TEXT NOT NULL
);

CREATE TABLE tb_tecnico (
    id_tecnico INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_tecnico TEXT NOT NULL UNIQUE
);

CREATE TABLE tb_copa (
    ano INTEGER PRIMARY KEY,
    pais_sede TEXT NOT NULL,
    abrev_campeao TEXT,
    abrev_vice TEXT,
    abrev_terceiro TEXT,
    abrev_quarto TEXT,
    qtd_gols INTEGER NOT NULL,
    times_classificados INTEGER NOT NULL,
    partidas_jogadas INTEGER NOT NULL,
    publico_total INTEGER,
    FOREIGN KEY (abrev_campeao) REFERENCES tb_selecao(abrev_selecao),
    FOREIGN KEY (abrev_vice) REFERENCES tb_selecao(abrev_selecao),
    FOREIGN KEY (abrev_terceiro) REFERENCES tb_selecao(abrev_selecao),
    FOREIGN KEY (abrev_quarto) REFERENCES tb_selecao(abrev_selecao)
);

CREATE TABLE tb_partida (
    partida_id INTEGER PRIMARY KEY,
    rodada_id INTEGER NOT NULL,
    ano_copa INTEGER NOT NULL,
    data_hora TEXT NOT NULL,
    fase TEXT NOT NULL,
    id_estadio INTEGER NOT NULL,
    abrev_time_casa TEXT NOT NULL,
    abrev_time_visitante TEXT NOT NULL,
    gols_casa INTEGER NOT NULL DEFAULT 0,
    gols_visitante INTEGER NOT NULL DEFAULT 0,
    publico INTEGER NULL,
    gols_tempo_reg_casa INTEGER,
    gols_tempo_reg_visitante INTEGER,
    condicoes_vitoria TEXT NULL,
    FOREIGN KEY (ano_copa) REFERENCES tb_copa(ano),
    FOREIGN KEY (id_estadio) REFERENCES tb_estadio(id_estadio),
    FOREIGN KEY (abrev_time_casa) REFERENCES tb_selecao(abrev_selecao),
    FOREIGN KEY (abrev_time_visitante) REFERENCES tb_selecao(abrev_selecao)
);

CREATE TABLE tb_partida_jogador (
    partida_id INTEGER NOT NULL,
    id_jogador INTEGER NOT NULL,
    abrev_selecao TEXT NOT NULL,
    id_tecnico INTEGER NOT NULL,
    numero_camisa INTEGER NOT NULL,
    tipo_escalacao TEXT NOT NULL,
    posicao TEXT NULL,
    eventos TEXT NULL,
    PRIMARY KEY (partida_id, id_jogador),
    FOREIGN KEY (partida_id) REFERENCES tb_partida(partida_id),
    FOREIGN KEY (id_jogador) REFERENCES tb_jogador(id_jogador),
    FOREIGN KEY (abrev_selecao) REFERENCES tb_selecao(abrev_selecao),
    FOREIGN KEY (id_tecnico) REFERENCES tb_tecnico(id_tecnico)
);
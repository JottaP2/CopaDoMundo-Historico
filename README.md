# Projeto de Banco de Dados I - Análise Histórica das Copas do Mundo FIFA

Este repositório contém o projeto prático de Modelagem, Normalização e Análise de Dados desenvolvido para a avaliação da disciplina de **Banco de Dados I**. O projeto consiste na extração de dados brutos sobre a história das Copas do Mundo (Kaggle), e estruturação em um banco de dados relacional local utilizando **SQLite**.


## Objetivo Principal do Projeto

O objetivo central desta atividade foi aplicar conceitos práticos de engenharia de dados e sistemas de bancos de dados relacionais, trabalho feito para obtenção de nota para avaliação 02 da disciplica de Banco de Dados 1

## Tecnologias Utilizadas

* **Banco de Dados:** SQLite 3
* **Linguagem de Carga:** Python 3 (Bibliotecas: `pandas`, `sqlite3`, `os`)
* **Dados Originais:** FIFA World Cup Dataset (Kaggle)

---

## Arquitetura e Mapeamento do Banco de Dados Relacional
Abaixo está representado o Diagrama Entidade-Relacionamento (DER) do ecossistema de dados das Copas do Mundo. A estrutura foi totalmente normalizada para mitigar redundâncias e inconsistências, organizando a massa de dados original em 8 entidades core interconectadas por chaves estrangeiras (FOREIGN KEY), garantindo uma forte integridade referencial.
### 📊 Diagrama Entidade-Relacionamento (DER)
<img width="1653" height="1147" alt="Untitled" src="https://github.com/user-attachments/assets/45d2a189-0ff4-4389-be6c-e1b43dfa3351" />

* **`tb_selecao`**: Entidade centralizadora das federações nacionais. Armazena a sigla abreviada de três letras (`abrev_selecao`) como chave primária (`PK`) e o nome oficial do país.
* **`tb_copa`**: Tabela cronológica que mapeia cada edição do torneio pelo seu `ano` (`PK`). Ela se conecta à `tb_selecao` por meio de chaves estrangeiras (`FK`) para referenciar o pódio histórico (`abrev_campeao`, `abrev_vice`, `abrev_terceiro`, `abrev_quarto`).
* **`tb_cidade` e `tb_estadio`**: Estruturas geográficas normalizadas. Um estádio pertence obrigatoriamente a uma cidade por meio do `id_cidade` (`FK`), eliminando a repetição textual desnecessária de nomes de cidades no histórico de jogos.
* **`tb_partida`**: Entidade operacional que registra os dados agregados de cada confronto (gols regulamentares, público total, placar final e condições de vitória). Conecta-se diretamente ao estádio onde ocorreu a partida (`id_estadio`) e ao ano da Copa correspondente (`ano_copa`).
* **`tb_jogador` e `tb_tecnico`**: Cadastros isolados contendo os IDs únicos (`PK`) e nomes dos profissionais de futebol, evitando que dados biográficos fiquem duplicados a cada nova listagem de jogo.
* **`tb_partida_jogador` (Tabela Fato/Associativa)**: O coração analítico do banco de dados. Esta tabela resolve o relacionamento de muitos-para-muitos (`N:M`) entre partidas, jogadores e técnicos. Ela mapeia exatamente a escalação de cada jogo, registrando a numeração da camisa, posição tática, tipo de escalação e a string consolidada de `eventos` (onde são extraídos os gols e cartões em minutos específicos).

## Dossiê de Consultas Analíticas (SQL)

## Vídeo explicando a consulta 🏆
### Em anos que o Brasil foi campeão, quem foi o primeiro e o último jogador a marca pela seleção?


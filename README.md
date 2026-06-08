# Projeto de Banco de Dados I - Análise Histórica das Copas do Mundo FIFA

Este repositório contém o projeto prático de Modelagem, Normalização e Análise de Dados desenvolvido para a avaliação da disciplina de **Banco de Dados I**. O projeto consiste na extração de dados brutos sobre a história das Copas do Mundo (Kaggle), e estruturação em um banco de dados relacional local utilizando **SQLite**.


## Objetivo Principal do Projeto

O objetivo central desta atividade foi aplicar conceitos práticos de engenharia de dados e sistemas de bancos de dados relacionais, trabalho feito para obtenção de nota para avaliação 02 da disciplica de Banco de Dados 1

### Estrutura do Projeto

| Diretório / Arquivo | Tipo | Descrição |
| :--- | :---: | :--- |
| 📁 **certificados-datacamp/** | Pasta | Guarda as certificações obtidas na plataforma DataCamp. |
| 📁 **database/** | Pasta | Armazena os scripts SQL e o banco de dados local. |
| └── 📄 `Consultas.sql` | Arquivo | Contém as 15 consultas analíticas sobre a história das Copas. |
| └── 📄 `DDL - Tabelas.sql` | Arquivo | Script de criação das tabelas e chaves estrangeiras (SQLite). |
| └── 💾 `fifawordcup-bd1-av2.db` | Arquivo | Arquivo de banco de dados SQLite já populado. |
| 📁 **dataset/** | Pasta | Armazena os arquivos originais de dados brutos. |
| └── 📊 `WorldCupMatches.csv` | Arquivo | Dados históricos das partidas disputadas. |
| └── 📊 `WorldCupPlayers.csv` | Arquivo | Dados de escalação e eventos dos jogadores por partida. |
| └── 📊 `WorldCups.csv` | Arquivo | Estatísticas gerais de cada edição das Copas. |
| 🐍 `carregar_dados.py` | Arquivo | Script em Python responsável por ler os CSVs e popular o banco de dados. |



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
Este documento apresenta uma visão geral das 15 consultas SQL desenvolvidas para analisar o banco de dados histórico da Copa do Mundo FIFA. A tabela abaixo resume o título e o objetivo prático de cada consulta realizada no modelo.
| ID | Título da Consulta | Resumo do que a Consulta Faz |
| :---: | :--- | :--- |
| **01** | **Maiores Algozes do Brasil** | Identifica quais seleções mais venceram o Brasil em Copas do Mundo, trazendo o saldo total de confrontos, vitórias e derrotas brasileiras contra cada adversário. |
| **02** | **Maiores Marcadores da História** | Lista as 5 seleções com o maior volume de gols acumulados em todas as edições da história das Copas. |
| **03** | **Seleções Coadjuvantes** | Retorna os países que já participaram da competição, mas que nunca conseguiram terminar entre os 4 primeiros colocados (semifinal ou final). |
| **04** | **Edição com Maior Média de Gols** | Calcula e exibe qual ano e sede de Copa do Mundo registrou a maior média de gols por partida. |
| **05** | **Maiores Goleadas no Mata-Mata** | Busca os 5 estádios que sediaram os jogos com a maior diferença de gols (saldo) em fases eliminatórias *(perfeito para caçar o fantasma do Mineirão no 7x1)*. |
| **06** | **Primeiro e Último Gol nos Anos de Título** | Analisa os anos em que o Brasil foi campeão e descobre quais jogadores marcaram o primeiro gol da seleção na estreia e o último gol da campanha. |
| **07** | **Ranking de Participações** | Lista todas as seleções ordenadas pela quantidade de edições de Copas do Mundo que disputaram na história. |
| **08** | **Volume de Gols: Início vs. Fim** | Compara a eficiência e o cansaço dos times, somando os gols marcados nos primeiros 15 minutos de jogo e os gols tardios, feitos após os 80 minutos. |
| **09** | **Estatísticas de Viradas Históricas** | Conta quantas partidas tiveram uma reviravolta completa no placar durante o segundo tempo (equipes que foram para o intervalo perdendo e saíram vencedoras). |
| **10** | **Recordes de Público em Finais** | Localiza as duas partidas de final de Copa do Mundo que registraram o maior e o menor público pagante da história. |
| **11** | **Top 5 Artilheiros das Copas** | Identifica os 5 maiores goleadores da história dos mundiais, calculando a quantidade de gols através da contagem do caractere 'G' no campo de eventos. |
| **12** | **Jogadores com Mais Copas no Currículo** | Lista os atletas que tiveram a carreira mais longeva em Copas, exibindo quem disputou o maior número de edições diferentes. |
| **13** | **Melhores Defesas de Semifinalistas** | Encontra as 10 seleções que sofreram a menor média de gols por jogo em uma única edição, limitando o filtro a equipes que jogaram pelo menos 5 partidas e chegaram até as finais/semifinais. |
| **14** | **Evolução Histórica de Gols** | Cria um gráfico em tabela do acumulado de gols da história, mostrando o crescimento do número total de bolas na rede edição após edição. |
| **15** | **Raio-X do Rei Pelé** | Consolida o histórico completo de Pelé em Copas, mostrando o total de partidas jogadas, edições disputadas e gols oficiais registrados. |


## Vídeo explicando a consulta 🏆
### Em anos que o Brasil foi campeão, quem foi o primeiro e o último jogador a marca pela seleção?
https://github.com/user-attachments/assets/cc35daa5-a50e-4543-834b-73101889a9db




# Instalação do pacote tidyverse:
install.packages("tidyverse")

# Carrregando o pacote:
library(tidyverse)

# Os conflitos se dão por causa das funções filter() e lag(), que fazem parte do R-base
# Ambas as funções são substituidas pelas respectivas funções do dplyr
# Caso ainda queira usar as funções originais, utilize stats::filter() ou stats::lag()

# Outros pacotes a serem utilizados:
library(nycflights13)

# O pacote nycflights13 possui uma base de dados com todos os voos que passaram pelo
# Aeroporto de Nova York no ano de 2013, com diversas informações desses voos.
?flights
voos <- nycflights13::flights

voos

# Análise preliminar dos dados:
summary(voos)

## Dplyr
### filter()

# Comecemos filtrando os voos que aconteceram em janeiro:
filter(voos, month == 1)

# Podemos colocar mais de uma condição para o filtro, que será realizado em sequência:
filter(voos, month == 1, day ==1)

# Ou podemos utilizar o %in% para definir um conjunto de filtros:
filter(voos, month %in% c(11,12))

# Podemos também incluir operadores de comparação diferentes:
filter(voos, dep_delay <= 120)
filter(voos, dep_delay >= 120, arr_delay >= 120)
filter(voos, dest != "BOS")

# Valores missing (NA) devem ser cuidados com cuidado extra
# A maioria dos operadores não funcionam bem com NAs:
15 + NA
20 - NA
5 > NA
0 < NA
NA == 15
NA == NA

# Uma função útil para lidar com NAs é o is.na(), que retorna TRUE caso seja:
is.na(NA)
is.na(15)

filter(voos, is.na(air_time))
filter(voos, !is.na(air_time))

# Outra forma de lidar com NAs é por meio de funções que eliminam NAs, como a mean():
mean(c(1,2,4,9,NA))
mean(c(1,2,4,9,NA), na.rm = TRUE)

### arrange()

# Utilizamos o arrange() para reorganizar os dados de acordo com uma coluna:
arrange(voos, dep_time)

# Para reorganizar do maior para o menor, utilizar desc():
arrange(voos, desc(dep_time))


### select()

# Utilizamos o select() para selecionar alguma(s) coluna(s) do tibble:
select(voos, year, month, day)

# Podemos utilizar : para selecionar todas as colunas entre um intervalo:
select(voos, dep_time:arr_time)

# Podemos utilizar - para selecionar todas as colunas, com excessão das indicadas:
select(voos, -(year:day))

# Podemos utilizar alguns argumentos especiais para diferentes propósitos:
## Selecionar colunas que começam com uma string:
select(voos, starts_with("dep"))

## Selecionar colunas que terminam com uma string:
select(voos, ends_with("time"))

## Selecionar colunas que contenham uma string:
select(voos, contains("time"))

### mutate()

# Utilizamos a função mutate() para adicionar colunas a partir de colunas existentes:
# Primeiro, vamos selecionar algumas colunas que vamos utilizar:
voos2 <- select(voos, distance, air_time)

# Agora, vamos adicionar uma coluna de velocidade, dada por distância/tempo:
mutate(voos2, velocidade = distance/air_time)

# Podemos inclusive utilizar colunas recém-criadas para criar novas colunas:
mutate(voos2, km_m = distance/air_time, horas = air_time/60, km_h = distance/horas)

# Se a ideia é manter apenas as colunas recém-criadas, utilize transmute():
transmute(voos2, km_m = distance/air_time)

# Há uma gama de funções que podem ser úteis para criação de novas colunas:
(x <- c(1:10))

## Operadores aritméticos (+,-,*,/,^);
## Operadores modulares (%/% (divisão inteira) e %% (resto)):
transmute(voos,
          tempo = dep_time,
          hora = dep_time %/% 100,
          minuto = dep_time %% 100)

## Operadores de offsetting (lag() e lead())
lag(x)
lead(x)
## Operadores cumulativos (cumsum, cumprod e cummean):
cumsum(x)
cumprod(x)
cummean(x)

### summarise()

# A função summarise() é usada para criar medidas resumo de um data.frame:
summarise(voos, atraso_medio = mean(dep_delay, na.rm = TRUE)) # Utilizamos na.rm = TRUE para eliminar NAs

# Porém, essa função não é muito útil sozinha, pois poderíamos facilmente calcular essa média.
# Por isso, usamos outra ferramenta do dplyr: a função group_by():
por_dia <- group_by(voos, year, month, day)
por_dia

# Notem que o tible não mudou, pois a função group_by faz um agrupamento silencioso.
# Agora, vamos utilizar o summarise novamente:
summarise(por_dia, atraso_medio = mean(dep_delay, na.rm = TRUE))

# Vamos agora introduzir uma "função" que é a espinha dorsal do tidyverse: o pipe

### pipe

# O operador pipe faz parte do pacote magrittr, e foi implementado como parte fundamental do tidyverse.
# O operador "recebe" o que vem antes dele, e coloca como primeiro argumento da função depois dele:

# Digamos que queremos calcular o atraso médio por dia, como anteriormente. Temos três opções:

## Atribuir a objetos intermediarios:
por_dia <- group_by(voos, year, month, day)

atraso_dia <- summarise(por_dia, atraso_medio = mean(dep_delay, na.rm = TRUE))
atraso_dia

## Compor funções:
atraso_dia <- summarise(group_by(voos,year,month,day), atraso_medio = mean(dep_delay, na.rm = TRUE))
atraso_dia

## Utilizar o pipe:
atraso_dia <- voos %>% 
  group_by(year, month, day) %>% 
  summarise(atraso_medio = mean(dep_delay, na.rm = TRUE))

atraso_dia

# Para não precisarmos novamente utilizar na.rm, vamos criar outro data.frame sem os valores missing:
voos_reais <- voos %>% 
  filter(!is.na(dep_delay),!is.na(arr_delay))

# No nosso caso, os valores missing são voos cancelados, que não nos são úteis

# Outro exemplo: Queremos calcular a quantidade de voos por destino:
por_destino <- voos_reais %>% 
  group_by(dest) %>% 
  summarise(Quantidade = n())

por_destino

# Há uma gama de funções úteis para utilizar com sumários:
## Medidas de locação (mean() e median());
## Medidas de dispersão (sd() e var()):
voos_reais %>% 
  group_by(dest) %>% 
  summarise(desvio_distancia = sd(distance)) %>% 
  arrange(desc(desvio_distancia))

## Medidas de posição (min(), max(), quantile()):
voos_reais %>% 
  group_by(year, month, day) %>% 
  summarise(primeiro_voo = min(dep_time), ultimo_voo = max(dep_time))

## Medidas de contagem (n(), n_distinct(), sum(is.na())):
voos_reais %>% 
  group_by(dest) %>% 
  summarise(companhias = n_distinct(carrier))


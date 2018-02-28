Start Puma:

bundle exec puma -C ./config/puma.rb -p 3001

http://websha256.inclouds.com.ua/blockchain/get_blocks/3

This is example of a simple web app like rails.
It has:
  - Routes (Get, Post)
  - Models (ActiveRecord, migrations)
  - Views (Layout, Haml and method render in controllers)
  - Controllers

```
Задача - написать веб приложение, которое будет эмулировать ноду децентрализованной блокчейн сети. Она сможет общаться с другими нодами при помощи вызовов REST ендпоинтов, а так же ей можно управлять снаружи путем взаимодействия с такими же endpoint’ами
1) Имеет внутреннее состояние - набор балансов id-ballance
Ballances: {‘111’:10,’222’:20,’xsdf’:13}


2) Историю изменения состояния хранит в виде блоков. Формат блока
{
hash:sha256,
prev_hash:sha256,
ts: timestamp,
tx: [{to:112,from:111,amount:123},{}] 



3) Реализует API для взаимодействия узлов друг с другом 
POST /management/add_transaction
  { from:string,
  to:string,
  amount:int}
POST /management/add_link
  { id:111,
  url:’http://192.168.1.111:3000’’}
GET /management/sync  - вызываем мы что б скачать с соседей начальный блокчейн

GET /management/state
  {id:string,name:string,last_hash:sha256, neighbours:[{id:’111’,url:’http://someurl.com.ua:8080’}, {id:‘222’,url:’http://anotherurl.com.ua:8080’}, {id:’333’,url:’https://thirdurl.com’}], url:’http://192.168.1.111:3000’’}

GET /blockchain/get_blocks/:num_blocks
[{ hash:string,
  prev_hash:string,
  ts:unix_timestamp,int,
  tx:[{
  from:string,
  to:string,
  amount:int },   {} ,  {}] }]

POST /blockchain/receive_update
{  sender_id:string,  block:{block} }
  
Формат ответа на API:
{success:true/false, status:string, message:string}
ERR_WRONG_HASH


А теперь подробнее и с примерами

POST /management/add_transaction
Нужна что б добавить новую транзакцию. Когда накопилось 5 транзакций, они помещаются в блок. Для блока считается его хеш (см ниже) и он помещается в key-value хранилище, где key -  хеш блока, и value - содержимое блок. 
После этого этот блок рассылается всем соседям (см add_neighbour) путем обращения к ендпоинту http://neighbour_url/blockchain/receive_update (тоже см. ниже) при помощи метода POST и передачи ему этого блока (см описание receive_update). Если вызов receive_update какого-то соседа оканчивается неудачей, этого соседа нужно удалить из списка соседей.
input:
  { from:string,
  to:string,
  аmount:int
  }
output:
{ 
   success:bool,
   status: string,
   message: string
}

POST /management/add_link
Добавляется запись в массив “соседей” который будет позже использоваться для передачи им своих блоков и синхронизации с ними
input
  { id:111,
  url:’http://192.168.1.111:3000’’
}
output:
{ 
   success:bool,
   status: string,
   message: string
}

GET /management/sync  
Используется что б синхронизироваться с существующей сетью. При вызове этого ендпоинта нужно взять из первого соседа все его блоки (blockchain/get_blocks/10000) и скопировать себе. Если есть свои блоки их можно удалить .  Если сосед отвечает ошибкой, удалить этого соседа из массива соседей, и вернуть ошибку.
Input 
Нет
output:
{ 
   success:bool,
   status: string,
   message: string
}


GET /management/state
Просто показывает текущее состояние узла (ноды). Используется монитором для визуального отображения. Url должен быть с префиксом и реальный, по которому вас можно достать снаружи, не localhost
Input
Нет
output
  {id:string,name:string,last_hash:sha256, neighbours:[‘id1’, ‘id2’,’id3’], url:’http://192.168.1.111:3000’’}


GET /blockchain/get_blocks/:num_blocks
Выдает список последних блоков. Начиная от последнего и вглубь пока не наберется num_blocks . рекомендуется взять хеш последнего блока (его лучше хранить в каком-то месте что б еще и в /management/state показывать). По этому хешу достать блок из key-value хранилища. У этого блока взять его last_hash и достать предыдущий блок. И так далее пока не наберется num_blocks
Input
Нет
output
[{ hash:string,
  prev_hash:string,
  ts:unix_timestamp,int,
  tx:[{
  from:string,
  to:string,
  amount:int },   {} ,  {}] }]


POST /blockchain/receive_update
Ендпоинт для получения обновлений от других узлов. Обновление включает id отправителя и один блок. 
Если у этого блока last_hash такой же как у вас хеш последнего блока, то просто добавляем блок к себе
Если у этого блока last_hash такой же как last_hash последнего блока, то сравниваем ts этих блоков и оставляем тот у которого ts меньше. 
В противном случае указанный блок игнорируем (с сообщением об ошибке в output)
Если блок приняли (или поместив его вверх своей цепочки или заменив свой последний блок этим блоком), то нужно раздать этот блок своим соседям кроме отправителя (т.е. исключая sender_id)
input
{  sender_id:string,  block:{block} }
Output
{ 
   success:bool,
   status: string,
   message: string
}

Формат Блока
{ hash:string,
  prev_hash:string,
  ts:unix_timestamp,int,
  tx:[{
  from:string,
  to:string,
  amount:int },   {} ,  {}] 
}

Как считать хеш?
На данный момент неважно, тк мы не верифицируем блоки. Но в принципе можно придерживаться такой схемы
sha256(prev_hash + ts.toString() + tx[0].from + tx[0].to+tx[0].amount.toString() + tx[1].from + tx[1].to + tx[1].amount.toString() … )
```
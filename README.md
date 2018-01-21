Start Puma:

bundle exec puma -C ./config/puma.rb -p 3001

http://websha256.inclouds.com.ua/add_data

http://websha256.inclouds.com.ua/last_blocks/10

This is example of a simple web app like rails.
It has:
  - Routes (Get, Post)
  - Models (ActiveRecord, migrations)
  - Views (Layout, Haml and method render in controllers)
  - Controllers

```
POST /add_data
 на вход принимает строку данных , или в виде объекта json, {data: 'somadata'}, или традиционная url-encoded форма  data:somedata
 данные сохраняются во внутреннем буфере (любой удобный способ хранить данные)
 когда во внутреннем буфере набралось 5 записей (5 строк), из них формируется блок - json объект следующего формата
{
  previous_block_hash: '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
  rows: ['data1','data2','data3','data4','data5'],
  timestamp: 12123889,
  block_hash: '1b4f0e9851971998e732078544c96b36c3d01cedf7caa332359d6f1d83567014'
}
в котором записан хеш предыдущего блока, массив из 5 строк, время формирования блока в unix_timestamp (или другом удобном формате) и хеш от трех предыдущих полей.
 этот блок сохраняется во внутреннее key-value хранилище (любое удобное, хоть в память) в виде сериализованной строки или как-есть json-объектом, если хранилище это поддерживает. Key - это хеш (то же значение что  в поле block_hash), Value - сам блок
для хеширования использовать sha256, 
для первого (нулевого) блока предыдущий хеш считать нулем. т.е. previous_block_hash: '0' или previous_block_hash: 0
GET /last_blocks/10
 на вход получает количество последних блоков
 выдает в ответ массива из N последних блоков в формате JSON

[
{
previous_block_hash: ‘1b4f0e9851971998e732078544c96b36c3d01cedf7caa332359d6f1d83567014’,
Rows:[‘data5’,’data6’,’data7’,’data8’,’data9’}],
timestamp: 123123123
block_hash: ‘a98ec5c5044800c88e862f007b98d89815fc40ca155d6ce7909530d792e909ce’
},
{
….
}
]
Про сессии, куки, авторизацию, разделение пользователей заморачиваться не нужно.
```
-- Практическое задание по теме “Оптимизация запросов”

-- Задание № 1
-- Создайте таблицу logs типа Archive. Пусть при каждом создании записи в таблицах users, catalogs и products в таблицу logs 
-- помещается время и дата создания записи, название таблицы, идентификатор первичного ключа и содержимое поля name.
USE shop;

-- создаем таблицу типа ARCHIVE
CREATE TABLE logs
	(id INT UNSIGNED NOT NULL,
	table_name VARCHAR(255),
	value_name VARCHAR(255),
	cerated_at DATETIME DEFAULT now()
	) ENGINE=ARCHIVE;  

-- создаем соответствующие триггеры на таблицу users, catalogs и products
-- users
DROP TRIGGER IF EXISTS users_archive_insert;
DELIMITER //
CREATE TRIGGER users_archive_insert BEFORE INSERT ON users
FOR EACH ROW
BEGIN
	INSERT INTO logs VALUE (LAST_INSERT_ID(), 'users', NEW.name, NEW.created_at);
END//

-- catalogs
DROP TRIGGER IF EXISTS catalogs_archive_insert;
CREATE TRIGGER catalogs_archive_insert BEFORE INSERT ON catalogs
FOR EACH ROW
BEGIN
	INSERT INTO logs VALUE (LAST_INSERT_ID(), 'catalogs', NEW.name, NEW.created_at);
END//

-- products
DROP TRIGGER IF EXISTS products_archive_insert;
CREATE TRIGGER products_archive_insert BEFORE INSERT ON products
FOR EACH ROW
BEGIN
	INSERT INTO logs VALUE (LAST_INSERT_ID(), 'products', NEW.name, NEW.created_at);
END//
DELIMITER ;

-- проверяем
INSERT INTO users VALUE (NULL,'Hksdfnskj Ljsdsjf', 1988-01-01, now(), now());
INSERT INTO catalogs VALUE (NULL,'Аксессуары');
INSERT INTO products VALUE (NULL, 'iPods', 'Наушники для iPhone', 15000,6,now(),now())
-- всё работает
SELECT * from logs;


-- Задание № 2
-- (по желанию) Создайте SQL-запрос, который помещает в таблицу users миллион записей.

-- создал тестовую табличку для экспериментов
CREATE TABLE test_user 
(id SERIAL PRIMARY KEY, 
first_name VARCHAR(255), 
last_name VARCHAR(255), 
created_at DATETIME DEFAULT now());

SELECT * FROM test_user;
TRUNCATE TABLE test_user;

-- самое простоечто пришло в голову это декартово произведение у меня в таблице users 1000 строк таким образом при объединении
-- её саму с собой через JOIN мы получаем 1000 000 строк и соответственно SELECT в INSERT только перед выполнением нужно разрешить
-- медленные запросы иначе база его оборвёт. На сколько я понимаю этот запрос практического применения не имеет кроме как тестировочного
-- смысла проверить производительность или поиграть с большими данными поэтому надеюсь мой способ имеет место быть или его как то нужно
-- было делать с учётом темы занятия?  

INSERT INTO 
	test_user(first_name, last_name, created_at) 
SELECT 
	u.first_name, u.last_name, u.created_at 
FROM users u JOIN users u2;

-- интересный вариант через рекурсию только нужно разрешить глубину до 1000 000 иначе ругается. Нонаверное не очень удачный вариант
-- в смысле ресурсозатрат
INSERT INTO test_user
WITH RECURSIVE insert_mln(n, first_name, last_name, created_at) AS
(
  SELECT 1 AS n, first_name, last_name, created_at FROM users WHERE users.id = 5
  UNION ALL
  SELECT 1+n, first_name, last_name, created_at FROM insert_mln WHERE n < 1000000 
) SELECT * FROM insert_mln;
-- проверяем очищаем
SELECT * FROM test_user;
TRUNCATE TABLE test_user;


-- ************************************************************************************************************************

-- Практическое задание по теме “NoSQL”

-- Задание № 1
-- В базе данных Redis подберите коллекцию для подсчета посещений с определенных IP-адресов.

-- предположу что оптимальной коллекцией для хранения указанных данных будет хеш-таблица так как по мимо ip адреса необходимо хранить
-- время входа и завершения сессии возможно ещё какие то данные что позволяет удобно хранить в структурированном порядке указанный тип данных

-- пример хранени внесения и структура хранения инфориации, при этом текущее время начала и завершения могут передавться из приложения
-- HMSET user_1 ip "192.168.57.87" data_conect "2019-12-18 12:18:01" data_disconect "2019-12-18 15:01:15"

-- получение значения
-- hgetall user_1
-- 1) "ip"
-- 2) "192.168.57.87"
-- 3) "data_conect"
-- 4) "2019-12-18 12:18:01"
-- 5) "data_disconect"
-- 6) "2019-12-18 15:01:15"

-- или по ключу например ip адрес
-- hget user_1 ip
-- "192.168.57.87"

-- надеюсь я правильно понял задачу

-- Задание № 2
-- При помощи базы данных Redis решите задачу поиска имени пользователя по электронному адресу и наоборот, поиск 
-- электронного адреса пользователя по его имени.

-- учитывая что в Redis отсутствует полноценный поис(только модуль на официальном сайте видел) то в данном случае вариантов
-- реализациии достаточно много учитывая, что в конечном итоге поис будет осущетсвлятся програмно скорее всего ну или запрос будет 
-- формироваться из приложения. На ум пришло лиюо использовать опять хэш таблицы и по ним уже осуществляь поиск по ключу например
-- формат данных может быть такой:  
-- HMSET user_1 Alex alex@mail.ru alex@mail.ru Alex
-- HMSET user_2 Ivan dgdfg@mail.ru dgdfg@mail.ru Ivan

-- ищем значения
-- HGET user_1 Alex 
-- alex@mail.ru
-- HGET user_2 dgdfg@mail.ru
-- Ivan

-- Ещё вариант через множества учитывая, что элементы в одном наборе уникальны (Имя, майл) то возможно через вычитание
-- или пересечение множеств, однако этот вариан сложнее чем если использовать обычный поиск чере ключи 
-- создаем тестовые данные
-- SADD Alex alex@mail.ru  
-- создаем условие поиска
-- SADD sh1 Alex
-- вычитаеммножества
-- SDIFF sh1 Alex
-- alex@mail.ru

-- или через обычные строки например
-- MSET Alex alex@m.ru alex@m.ru Alex
-- ищем
-- GET Alex
-- alex@m.ru
-- GET alex@m.ru
-- Alex

-- Задание № 3
-- Организуйте хранение категорий и товарных позиций учебной базы данных shop в СУБД MongoDB.
use shop;
select * from catalogs;
select * FROM products;

-- работа с Mongodb
-- создаем базу данных
-- use shop
-- создаем две коллекции(аналог табличек реляционных баз)
-- db.createCollection("catalogs")
-- { "ok" : 1 }
-- db.createCollection("products")
-- { "ok" : 1 }
-- db.catalogs.insert({1:"Процессоры", 2:"Материнские платы", 3:"Видеокарты", 4:"Жесткие диски", 5:"Оперативная память"})
-- с датами сильно не рабирался поэтому вставил функцию которую нашёл
db.products.insert(
					{
					name: "Intel Core i3-8100",
					description: "Процессор для настольных персональных компьютеров, основанных на платформе Intel",
					price: 7890,	
					catalog_id: 1,
					created_at: new Date(),	
					updated_at: new Date(),
					})
					
-- время и дата проставились автоматически
-- db.products.find()
-- { "_id" : ObjectId("5dfbf6ec3c8c639d3d1e86e9"), "name" : "Intel Core i3-8100", "description" : "Процессор для настольных персональных компьютеров, основанных на платформе Intel", "price" : 7890, "catalog_id" : 1, "created_at" : ISODate("2019-12-19T22:17:16.636Z"), "updated_at" : ISODate("2019-12-19T22:17:16.636Z") }
					
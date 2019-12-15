-- Практическое задание по теме “Транзакции, переменные, представления”
-- Задание № 1 В базе данных shop и sample присутствуют одни и те же таблицы, учебной базы данных. Переместите запись id = 1 из 
-- таблицы shop.users в таблицу sample.users. Используйте транзакции.

-- подготовка
USE shop;
CREATE DATABASE IF NOT EXISTS sample;
USE sample;
CREATE TABLE `users` (
  `id` SERIAL PRIMARY KEY,
  `name` varchar(255),
  `birthday_at` varchar(255),
  `created_at` datetime DEFAULT now(),
  `updated_at` datetime DEFAULT now() ON UPDATE NOW()
);
-- начинаем транзакцию
START TRANSACTION;
USE shop;
SELECT * FROM users WHERE id = 1;
USE sample;
INSERT INTO users SELECT * FROM shop.users WHERE id = 1;
SELECT * FROM users WHERE id = 1;
USE shop;
DELETE FROM users WHERE id = 1;
SELECT * FROM users WHERE id = 1;
COMMIT;
-- и заканчиваем
-- Задание № 2 Создайте представление, которое выводит название name товарной позиции из таблицы products и соответствующее 
-- название каталога name из таблицы catalogs.

-- впринципе тут достаточно просто пояснять думаю нечего
SELECT * FROM products;
SELECT * FROM catalogs;
CREATE OR REPLACE VIEW merg (name, catalog) AS SELECT p.name, c.name FROM catalogs c JOIN products p ON p.catalog_id = c.id;
SELECT * from merg;

-- Задание № 3 (по желанию) Пусть имеется таблица с календарным полем created_at. В ней размещены разряженые календарные записи 
-- за август 2018 года '2018-08-01', '2018-08-04', '2018-08-16' и 2018-08-17. Составьте запрос, который выводит полный список 
-- дат за август, выставляя в соседнем поле значение 1, если дата присутствует в исходном таблице и 0, если она отсутствует.

-- по это задаче конечно не совсем понятно надеюсь решение хотя бы приблизительно правильное. Вопрос с генерацией дат всего месяца
-- августа 2018! Их необходимо в ручную задавать или можно на любой имеющейся таблице у которой число строк больше числа дней в 
-- месяце?(я использовал второй вариант)

-- создаем таблицу календарь с указанными полями
CREATE TABLE calendar (id SERIAL PRIMARY KEY, created_at DATE);
-- наполняем её 
INSERT INTO calendar(created_at) VALUES ('2018-08-01'), ('2018-08-04'), ('2018-08-16'), ('2018-08-17');
SELECT * FROM calendar;
-- создаем переменную с датой от которой будем генерировать месяц
SET @d := '2018-07-31';
-- создаем временную таблицу для хранения всех дат за август 2018
CREATE TEMPORARY TABLE month_aug(id SERIAL PRIMARY KEY, avg_month DATE);
-- наполняем её датами с помощью переменной
INSERT INTO month_aug SELECT NULL, @d := @d + INTERVAL 1 DAY FROM likes WHERE @d < '2018-08-31';
SELECT * FROM month_aug; 
-- и делаем запрос с помощью левого объединения по одинаковому столбцу id используя оператор IF
SELECT m.avg_month, IF(m.avg_month IN (SELECT created_at FROM calendar), 1, 0) FROM month_aug m LEFT JOIN calendar c USING(id);
-- DROP TABLE calendar;
-- DROP TABLE month_aug;


-- Задание № 4 (по желанию) Пусть имеется любая таблица с календарным полем created_at. Создайте запрос, который удаляет 
-- устаревшие записи из таблицы, оставляя только 5 самых свежих записей.

-- берём дляпримера таблицу likes сортируем по полю создания created_at в обратном порядке от новых к старым и оставляем только 
-- 5 первых присваиваем значение переменной этого сотлбца, что по определению присвоит ей последнюю дату
-- удаляем все записи из таблицы у которых поле created_at больше значения переменной  
SELECT @d := created_at FROM likes ORDER BY created_at DESC LIMIT 5; 
-- проверяем запрос
SELECT * FROM likes WHERE created_at <= @d; 
-- удаляем значения оставляем те что удовлетворяют условию
DELETE FROM likes WHERE created_at >= @d;

-- ***********************************************************************************************************************
-- Практическое задание по теме “Администрирование MySQL” (эта тема изучается по вашему желанию)
-- ***********************************************************************************************************************
-- Задание № 1 Создайте двух пользователей которые имеют доступ к базе данных shop. Первому пользователю shop_read должны 
-- быть доступны только запросы на чтение данных, второму пользователю shop — любые операции в пределах базы данных shop.

SELECT Host, User FROM mysql.user;
-- создаем двух пользователей
CREATE USER shop_read IDENTIFIED WITH sha256_password BY '111';
CREATE USER shop_all IDENTIFIED WITH sha256_password BY '111';
-- назначаем им права
GRANT SELECT ON shop.* TO shop_read;
GRANT ALL ON shop.* TO shop_all;

-- Задание № 2 (по желанию) Пусть имеется таблица accounts содержащая три столбца id, name, password, содержащие первичный ключ, 
-- имя пользователя и его пароль. Создайте представление username таблицы accounts, предоставляющий доступ к столбцам id и name. 
-- Создайте пользователя user_read, который бы не имел доступа к таблице accounts, однако, мог бы извлекать записи из представления 
-- username.

-- подготовка
CREATE TABLE `accounts` (
  `id` SERIAL PRIMARY KEY,
  `name` varchar(255),
  `password` varchar(255)
);
INSERT INTO accounts VALUES (NULL,'Petr', 'qweqw'), (NULL,'Alex','23e3f2'),(NULL,'Jen','f3334');
SELECT * FROM accounts;
-- создаем представление
CREATE OR REPLACE VIEW username AS SELECT id, name FROM accounts;
SELECT * FROM username;
-- создаем пользователя
CREATE USER shop_read IDENTIFIED WITH sha256_password BY '111';
-- назначаем ему соответствующие права
GRANT SELECT ON shop.username TO shop_read;


-- ************************************************************************************************************************
-- Практическое задание по теме “Хранимые процедуры и функции, триггеры"
-- ************************************************************************************************************************
-- Задание № 1 Создайте хранимую функцию hello(), которая будет возвращать приветствие, в зависимости от текущего времени суток.
-- С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", с 12:00 до 18:00 функция должна возвращать фразу "Добрый день", 
-- с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".

-- Получаем текущее время с помощью now() преобразуем в часы через hour() и задаем условие ветвления выводя приветствие
-- почемуто не сработало NOT DETERMINISTIC а вот с READS SQL DATA отработало на УРА?
DELIMITER //
DROP FUNCTION IF EXISTS hello//
CREATE FUNCTION hello()
RETURNS TINYTEXT READS SQL DATA 
BEGIN
	IF (hour(now()) > 6 AND hour(now()) < 12) THEN
		RETURN 'Доброе утро!';
	ELSEIF (hour(now()) > 12 AND hour(now()) < 18) THEN
		RETURN 'Добрый день!';
	ELSEIF (hour(now()) > 18 AND hour(now()) < 24) THEN
		RETURN 'Добрый вечер!';
	ELSE
		RETURN 'Доброй ночи!';
    END IF;
END//
DELIMITER ;
select now(), hello();

-- попробовал через процедуру показалось проще
DELIMITER //
DROP PROCEDURE IF EXISTS hello//
CREATE PROCEDURE hello() 
BEGIN
	IF (hour(now()) > 6 AND hour(now()) < 12) THEN
		SELECT 'Доброе утро!';
	ELSEIF (hour(now()) > 12 AND hour(now()) < 18) THEN
		SELECT 'Добрый день!';
	ELSEIF (hour(now()) > 18 AND hour(now()) < 24) THEN
		SELECT 'Добрый вечер!';
	ELSE
		SELECT 'Доброй ночи!';
    END IF;
END//
DELIMITER ;
select hour(now());
CALL hello();

-- Задание № 2 В таблице products есть два текстовых поля: name с названием товара и description с его описанием. Допустимо 
-- присутствие обоих полей или одно из них. Ситуация, когда оба поля принимают неопределенное значение NULL неприемлема. 
-- Используя триггеры, добейтесь того, чтобы одно из этих полей или оба поля были заполнены. При попытке присвоить полям 
-- NULL-значение необходимо отменить операцию.


-- создал два тригера один на вставку другой на обновление. логика следующая: при изменении внеснии данных допускается только 
-- когда один из двух столбцов таблицы может принимать значение NULL если образуеться запись где оба столбца примут значение NULL
-- операция не проходит сохраняются старые значения
  
-- тригер на обновление(изменение)
DROP TRIGGER IF EXISTS products_name_description_update;
DELIMITER //
CREATE TRIGGER products_name_description_update BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    IF OLD.`name` IS NULL AND NEW.`description` IS NULL THEN
		SET NEW.`description` = OLD.`description`;
	ELSEIF NEW.`name` IS NULL AND OLD.`description` IS NULL THEN
		SET NEW.`name` = OLD.`name`;
	ELSEIF NEW.`name` IS NULL AND NEW.`description` IS NULL THEN
		SET NEW.`name` = OLD.`name`;
		SET NEW.`description` = OLD.`description`;
    END IF;
END//
DELIMITER ;

-- тригер на вставку нового значения
DROP TRIGGER IF EXISTS products_name_description_insert;
DELIMITER //
CREATE TRIGGER products_name_description_insert BEFORE INSERt ON products
FOR EACH ROW
BEGIN
	DECLARE new_name TINYTEXT;
	DECLARE new_description TINYTEXT;
	SELECT `name` INTO new_name FROM products ORDER BY RAND() LIMIT 1;
	SELECT `description` INTO new_description FROM products ORDER BY RAND() LIMIT 1;
    IF NEW.`name` IS NULL AND NEW.`description` IS NULL THEN
		SET NEW.`name` = COALESCE(NEW.`name`, new_name);
		SET NEW.`description` = COALESCE(NEW.`description`, new_description);
    END IF;
END//
DELIMITER ;

-- проверяем
UPDATE products SET name = NULL WHERE id = 7;
UPDATE products SET description = NULL WHERE id = 7;
UPDATE products SET description = NULL, name = NULL WHERE id = 7;
SELECT * FROM products;
-- проверяем
INSERT INTO products(id, name, description, price, catalog_id) VALUE (NULL, NULL, 'Процессор будущего Intel.', '777.00', '1');
INSERT INTO products(id, name, description, price, catalog_id) VALUE (NULL, 'Intel Core i9', NULL, '777.00', '1');
INSERT INTO products(id, name, description, price, catalog_id) VALUE (NULL, NULL, NULL, '777.00', '1');
SELECT * FROM products;

-- Задание № 3 (по желанию) Напишите хранимую функцию для вычисления произвольного числа Фибоначчи. Числами Фибоначчи называется 
-- последовательность в которой число равно сумме двух предыдущих чисел. Вызов функции FIBONACCI(10) должен возвращать число 55.

-- сделал следубщую логику: определяем переменные цикла и двух чисел в одно из них попеременно будем сохранять сумму. Поочередность 
-- сохранения определил через чётность. В конце выводим наибольшее из двух это и есть конечное запрашиваемое. Ну и дополнительная проверка
-- если запрашивается 0 число.
DELIMITER //
DROP FUNCTION IF EXISTS FIBONACCI//
CREATE FUNCTION FIBONACCI(num INT)
RETURNS INT READS SQL DATA
BEGIN
DECLARE a INT DEFAULT 0;
DECLARE b INT DEFAULT 1;
DECLARE i INT DEFAULT 0;
WHILE i < ABS(num) DO
	IF i%2 THEN SET a = a + b;
    ELSE SET b = b + a;
    END IF;
    SET i = i + 1;
END WHILE;
IF num = 0 THEN RETURN 0;
ELSEIF a > b THEN RETURN a;
ELSE RETURN b;
END IF;
END//
DELIMITER ;

SELECT FIBONACCI(0);
SELECT FIBONACCI(1);
SELECT FIBONACCI(5);
SELECT FIBONACCI(10);


-- ****************************************************************************************************************************
-- в прошлом ДЗ вы поставили мне отлично и посоветовали не использовать вложенные запросы, а также избегать дублирования кода и делать запросы 
-- более читаемыми и простыми. коментарии касались восновном 2 и 5 задания. Я поизучал материал переделал их и действительно, как мне показалось 
-- они стали значительно лучше. Если вас не затруднит посмотрите их тоже. ОЧЕНЬ интересна ваша критика и комментарии так как только когда
-- передалываешь ошибки глубже понимаешь материал и в каком направлении их ещё улучшать?

-- Задание № 2 Пусть задан некоторый пользователь. 
-- Из всех друзей этого пользователя найдите человека, который больше всех общался с нашим пользователем.

-- ПРОШЛЫЙ ЗАПРОС
SELECT `From` as `Name`,`To` AS `Friends`, COUNT(*) AS Total_messages FROM (
SELECT CONCAT(u.first_name,' ',u.last_name) AS `From`, CONCAT(u2.first_name,' ',u2.last_name) AS `To` FROM messages JOIN friendship ON from_user_id = user_id AND to_user_id = friend_id JOIN users u ON messages.from_user_id = u.id JOIN users u2 ON to_user_id = u2.id WHERE from_user_id = 4 AND status_id=2
UNION ALL
SELECT CONCAT(u4.first_name,' ',u4.last_name) AS `From`, CONCAT(u3.first_name,' ',u3.last_name) AS `To` FROM messages m JOIN friendship f ON m.from_user_id = f.user_id AND m.to_user_id = f.friend_id JOIN users u3 ON m.from_user_id = u3.id JOIN users u4 ON m.to_user_id = u4.id WHERE m.to_user_id = 4 AND status_id = 2
) AS mail GROUP BY `To`, `From` ORDER BY Total_messages DESC LIMIT 1;

-- ДОРАБОТАНЫЙ ЗАПРОС
SELECT
	CONCAT(u2.first_name,' ',u2.last_name) AS `From`, 
    CONCAT(u.first_name,' ',u.last_name) AS `To`, 
    COUNT(*) AS Total 
FROM users u 
JOIN messages m 
	ON u.id = m.from_user_id AND m.to_user_id = 4 OR u.id = m.to_user_id AND m.from_user_id = 4 
JOIN friendship f 
	ON 
		(m.from_user_id = f.user_id AND m.to_user_id = f.friend_id) 
    OR 
		(m.from_user_id = f.friend_id AND m.to_user_id = f.user_id) AND f.status_id = 2 
JOIN users u2 ON u2.id = 4 
GROUP BY `To` 
ORDER BY Total DESC LIMIT 1;
  
-- Задание № 5 
-- Найти 10 пользователей, которые проявляют наименьшую активность в использовании социальной сети.

-- ПРОШЛЫЙ ЗАПРОС
SELECT CONCAT(first_name,' ',last_name) AS `Name` , ps.Post, lk.Like, ms.Messages, (ps.Post*0.6 + lk.Like*0.35 + ms.Messages*0.25) as Total, 'Период с 2000-01-01 по н.в.' as Time FROM users LEFT JOIN
(SELECT users.id as user1,  COUNT(posts.id) as `Post` FROM users LEFT JOIN posts ON users.id = posts.user_id AND posts.created_at BETWEEN "2000-01-01" AND now() GROUP BY 1) as ps on users.id = ps.user1 LEFT JOIN
(SELECT users.id as user2,  COUNT(likes.id) as `Like` FROM users LEFT JOIN likes ON users.id = likes.user_id AND likes.created_at BETWEEN "2000-01-01" AND now() GROUP BY 1) as lk on users.id = lk.user2 LEFT JOIN
(SELECT users.id as user3,  COUNT(messages.id) as `Messages` FROM users LEFT JOIN messages ON users.id = messages.from_user_id AND messages.created_at BETWEEN "2000-01-01" AND now() GROUP BY 1) as ms on users.id = ms.user3 ORDER BY Total;

-- ДОРАБОТАНЫЙ ЗАПРОС
SELECT 
	CONCAT(first_name,' ',last_name) AS `Name`, 
	COUNT(DISTINCT p.id) as `Post`, 
    COUNT(DISTINCT l.id) as `Like`, 
    COUNT(DISTINCT m.id) AS Messag, 
    COUNT(DISTINCT p.id)*0.6+COUNT(DISTINCT l.id)*0.35+COUNT(DISTINCT m.id)*0.25 AS Total 
FROM users u 
	LEFT JOIN posts p ON u.id = p.user_id AND p.created_at BETWEEN "2000-01-01" AND now() 
	LEFT JOIN likes l on u.id = l.user_id AND l.created_at BETWEEN "2000-01-01" AND now() 
	LEFT JOIN messages m ON u.id = m.from_user_id AND m.created_at BETWEEN "2000-01-01" AND now() 
GROUP BY u.id 
ORDER BY Total;
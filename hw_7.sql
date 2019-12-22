-- Задача №1 
-- Составьте список пользователей users, которые осуществили хотя бы один заказ orders в интернет магазине.
use shop;

-- Если я правильно понял задачу то мы выводим корилирующим запросом имена пользователей который сделали 
-- заказы информация о которых храниться в таблице orders таким образом нулевых значений не будет. Получаем список 
-- покупателей которые сделали хотя бы один заказ и групируем его по user_id получая количество заказаов накаждого
SELECT 
	(SELECT name FROM users WHERE id = o.user_id) as name,
    COUNT(*) as total_orders
FROM 
	orders o
GROUP BY 
	user_id
ORDER BY total_orders;
-- Zboncak Sr.	1
-- Miss Bianka Cronin	1
-- Dante Carter IV	1
-- Jan Walsh	1

-- Задача №2
-- Выведите список товаров products и разделов catalogs, который соответствует товару.
-- ne наверное пояснять нечего сделал через JOIN ну и добавил GROUP_CONCAT для красоты 
SELECT
	c.name AS catalog,
	GROUP_CONCAT(p.name SEPARATOR '; ') AS product
FROM 
	products p
JOIN
	catalogs c
ON 
	p.catalog_id = c.id
GROUP BY p.catalog_id, c.id;
-- Процессоры	Intel Core i3-8100; Intel Core i5-7400; AMD FX-8320E; AMD FX-8320
-- Материнские платы	ASUS ROG MAXIMUS X HERO; Gigabyte H310M S2H; MSI B250M GAMING PRO

-- вариант без JOIN
SELECT 
	name AS product_name, 
    (select name FROM catalogs WHERE id = p.catalog_id) AS catalog 
FROM
	products p;


 
-- Задача №3
-- (по желанию) Пусть имеется таблица рейсов flights (id, from, to) и таблица 
-- городов cities (label, name). Поля from, to и label содержат английские названия городов, 
-- поле name — русское. Выведите список рейсов flights с русскими названиями городов.


-- Создал таблицы заполнил данными подменил столбцы английские на русские через столбец label 
DROP TABLE IF EXISTS flights;
CREATE TABLE flights(
	id SERIAL PRIMARY KEY,
	`from` VARCHAR(100),
	`to` VARCHAR(100)
);
INSERT INTO 
	flights(`from`, `to`) 
VALUES 
	('moscow', 'omsk'), ('novgorod', 'kazan'), ('irkutsk', 'moscow'), ('omsk','irkutsk'), ('moscow','kazan');
SELECT * FROM flights;

DROP TABLE IF EXISTS cities;
CREATE TABLE cities(
	`label` VARCHAR(100),
	`name` VARCHAR(100)
);
INSERT INTO 
	cities(`label`, `name`)
VALUES
	('moscow','Москва'), ('irkutsk','Иркутск'), ('novgorod','Новгород'), ('kazan','Казань'), ('omsk','Омск');
SELECT * FROM cities;

SELECT
	(SELECT `name` FROM cities WHERE `label` = f.`from`) AS `from`,
    (SELECT `name` FROM cities WHERE `label` = f.`to`) AS `to` 
FROM 
	flights f;


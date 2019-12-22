-- ЗАДАНИЕ №1
-- ВАРИАНТ ЧЕРЕ JOIN
SELECT
	u.name,
    count(*) AS total
FROM
	orders o
JOIN
	users u
ON
	o.user_id = u.id
GROUP BY o.user_id
ORDER BY total;

-- ЗАДАНИЕ №2
-- ВАРИАНТ С ПОМОЩЬЮ JOIN 

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


-- ЗАДАНИЕ № 3
-- ВАРИАНТ С ПОМОЩЬЮ JOIN 
SELECT 
	c.`name`, 
	cn.`name` 
FROM 
	cities c 
JOIN 
	flights f 
JOIN 
	cities cn 
ON 
	c.`label` = f.`from` AND cn.`label`= f.`to`;
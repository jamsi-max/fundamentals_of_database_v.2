use vk;
-- Задание № 1 Добавить внешние ключи FOREIGN KEY к таблицам

SELECT * FROM users;
-- внешние ключи не требуются

SELECT * FROM `profiles`;
-- добавляем внешний ключ к столбцу user_id на id в таблице users  при этом для DELETE решил поставить значение NO ACTION
-- так как в дальнейшем профиль может быть восстановлен, а столбец user_id имеет атрибут первичного ключа, что не даеёт 
-- возможности разрешить принимать ему NULL значения. Для photo_id на id в media по аналогии как на семинаре, однако я столкнулся
-- с другой ошибкой которая возникла из-за того, что сгенерированные значения в столбце photo_id были от 0 до 1000  а в 
-- столбце id(media) от 0 до 500 пришлось поломать голову но до причины добрался сам) немного подкорректировал столбцы  

-- разрешаем NULL
ALTER TABLE `profiles` MODIFY COLUMN photo_id INT(10) UNSIGNED;
-- немного корректируем данные в таблице. Наверное проще было удалить лишние значения? 
UPDATE `profiles` SET photo_id = (SELECT id FROM media LIMIT 1);

ALTER TABLE `profiles` 
	ADD FOREIGN KEY (user_id) 
    REFERENCES users (id)
		ON UPDATE CASCADE
		ON DELETE NO ACTION,
	ADD FOREIGN KEY (photo_id) 
    REFERENCES media (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL;

SELECT * FROM communities;
-- для столбца user_admin_id на id в таблице users при удалении пользователя у группы администратора не будет то есть NULL 
ALTER TABLE communities 
	ADD FOREIGN KEY (user_admin_id) 
    REFERENCES users (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL;

SELECT * FROM communities_users;
-- решил что все таки должны быть NULL значения в столбцах при удаления пользователя поэтому пришлось удалить 
-- первичный ключ после чего получилось разрешить NULL значения в столбцах 
ALTER TABLE communities_users DROP PRIMARY KEY; 
ALTER TABLE communities_users MODIFY COLUMN community_id INT(10) UNSIGNED;
ALTER TABLE communities_users MODIFY COLUMN user_id INT(10) UNSIGNED;

ALTER TABLE communities_users 
	ADD FOREIGN KEY (community_id) 
    REFERENCES communities (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
	ADD FOREIGN KEY (user_id) 
    REFERENCES users (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL;

-- ***********************************************************************************************************************
-- дальше делал всё по аналогии с передыдущими
-- ***********************************************************************************************************************

SELECT * FROM friendship;
ALTER TABLE friendship DROP PRIMARY KEY; 
ALTER TABLE friendship MODIFY COLUMN user_id INT(10) UNSIGNED;
ALTER TABLE friendship MODIFY COLUMN friend_id INT(10) UNSIGNED;
ALTER TABLE friendship MODIFY COLUMN status_id INT(10) UNSIGNED;

ALTER TABLE friendship 
	ADD FOREIGN KEY (user_id) 
    REFERENCES users (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
	ADD FOREIGN KEY (friend_id) 
    REFERENCES users (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
    ADD FOREIGN KEY (status_id) 
    REFERENCES friendship_statuses (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL;    


SELECT * FROM friendship_statuses;
-- не требуются

SELECT * FROM like_types;
-- не требуются

SELECT * FROM likes;
ALTER TABLE likes MODIFY COLUMN user_id INT(10) UNSIGNED;
ALTER TABLE likes MODIFY COLUMN target_id INT(10) UNSIGNED;
ALTER TABLE likes MODIFY COLUMN target_type_id INT(10) UNSIGNED;
ALTER TABLE likes MODIFY COLUMN like_type INT(10) UNSIGNED;

ALTER TABLE likes 
	ADD FOREIGN KEY (user_id) 
    REFERENCES users (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
	ADD FOREIGN KEY (target_id) 
    REFERENCES media (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
    ADD FOREIGN KEY (target_type_id) 
    REFERENCES target_types (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
	ADD FOREIGN KEY (like_type) 
    REFERENCES like_types (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL; 

SELECT * FROM media;
ALTER TABLE media MODIFY COLUMN media_type_id INT(10) UNSIGNED;
ALTER TABLE media MODIFY COLUMN user_id INT(10) UNSIGNED;

ALTER TABLE media 
	ADD FOREIGN KEY (media_type_id) 
    REFERENCES media_types (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
	ADD FOREIGN KEY (user_id) 
    REFERENCES users (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL;

SELECT * FROM media_types;
-- не требуются

SELECT * FROM messages;
ALTER TABLE messages MODIFY COLUMN from_user_id INT(10) UNSIGNED;
ALTER TABLE messages MODIFY COLUMN to_user_id INT(10) UNSIGNED;
ALTER TABLE messages MODIFY COLUMN attached_media_id INT(10) UNSIGNED;

ALTER TABLE messages 
	ADD FOREIGN KEY (attached_media_id) 
    REFERENCES media (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
	ADD FOREIGN KEY (to_user_id) 
    REFERENCES users (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
    ADD FOREIGN KEY (from_user_id) 
    REFERENCES users (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL;    

SELECT * FROM posts;
ALTER TABLE posts MODIFY COLUMN user_id INT(10) UNSIGNED;

ALTER TABLE posts 
	ADD FOREIGN KEY (attached_media_id) 
    REFERENCES media (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
	ADD FOREIGN KEY (user_id) 
    REFERENCES users (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL;

SELECT * FROM relation_statuses;
-- нетребуются

SELECT * FROM relations;
ALTER TABLE relations MODIFY COLUMN user_id INT(10) UNSIGNED;
ALTER TABLE relations MODIFY COLUMN relative_id INT(10) UNSIGNED;
ALTER TABLE relations MODIFY COLUMN relative_status_id INT(10) UNSIGNED;

ALTER TABLE relations 
	ADD FOREIGN KEY (relative_id) 
    REFERENCES users (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
	ADD FOREIGN KEY (user_id) 
    REFERENCES users (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
    ADD FOREIGN KEY (relative_status_id) 
    REFERENCES relation_statuses (id)
		ON UPDATE CASCADE
		ON DELETE SET NULL;

SELECT * FROM target_types;
-- не требуются

-- *********************************************************************************************
-- ЗАДАНИЯ К 6 УРОКУ С ПОМОЩЬЮ JOIN
-- *********************************************************************************************

-- Задание № 2 Пусть задан некоторый пользователь. 
-- Из всех друзей этого пользователя найдите человека, который больше всех общался с нашим пользователем.
SELECT * from users;
SELECT * from messages; 
SELECT * from friendship;
SELECT * from friendship_statuses;
-- Логика такая: групируем все сообщения отправленные условным пользователем(id=4) со всеми полученными сообщениями этим же пользователем
-- далее объединяем две таблицы через UNION сортируем по третьему столбцу который выводит общее число отправленных сообщений.
-- Что бы объединить всё переставил местами столбцы во второй таблице для того что бы легче было объединить входищие с исходящими 
-- и потомсортировать. 

SELECT `From` as `Name`,`To` AS `Friends`, COUNT(*) AS Total_messages FROM (
SELECT CONCAT(u.first_name,' ',u.last_name) AS `From`, CONCAT(u2.first_name,' ',u2.last_name) AS `To` FROM messages JOIN friendship ON from_user_id = user_id AND to_user_id = friend_id JOIN users u ON messages.from_user_id = u.id JOIN users u2 ON to_user_id = u2.id WHERE from_user_id = 4 AND status_id=2
UNION ALL
SELECT CONCAT(u4.first_name,' ',u4.last_name) AS `From`, CONCAT(u3.first_name,' ',u3.last_name) AS `To` FROM messages m JOIN friendship f ON m.from_user_id = f.user_id AND m.to_user_id = f.friend_id JOIN users u3 ON m.from_user_id = u3.id JOIN users u4 ON m.to_user_id = u4.id WHERE m.to_user_id = 4 AND status_id = 2
) AS mail GROUP BY `To`, `From` ORDER BY Total_messages DESC LIMIT 1;

-- Задание №3 
-- Подсчитать общее количество лайков, которые получили 10 самых молодых пользователей.

-- объединяем интересующие таблицы групируем по столбцу target_id из таблицы likes получаем количество лайков и сортируем по дате 
-- рождения соответственно ставим LIMIT 10. В отличае от запроса без JOIN тут не выводятся 0 значения только те пользователи
-- которые получили лайки при этом самые молодые

SELECT 
	CONCAT(u.first_name,' ',u.last_name) AS `Name`, 
    p.birthday, 
    COUNT(*) AS Total_likes
FROM `profiles` p 
	JOIN users u ON p.user_id=u.id 
    JOIN media m ON p.user_id=m.user_id 
    JOIN likes l ON m.id=l.target_id 
GROUP BY 1,2 ORDER BY birthday DESC LIMIT 10;

-- Задание № 4 
-- Определить кто больше поставил лайков (всего) - мужчины или женщины?
SELECT 
	if(p.sex='m','мужчины', 'женщины') AS `Category`, COUNT(*) AS total_likes 
FROM 
	likes l 
JOIN 
	`profiles` p 
ON l.user_id = p.user_id GROUP BY p.sex ORDER BY total_likes DESC; 

-- Задание № 5 
-- Найти 10 пользователей, которые проявляют наименьшую активность в использовании социальной сети.

-- ЭТО БЫЛО НЕ ПРОСТО!!! Хотел уже сдаться и решить что через JOIN такую задачу не решить всмысле тот алгоритм, что я использовал
-- в 6 задании и тут осенило, когда запрос выполнился чуть до потолкане подпрыгнул. Насколько онлогичнее и рациональнее по сравнению
-- со старым видно сразу ниже приложил старый запрос. 
-- Логика такая же ищем все посты, лайки и отправленные пользователями сообщения и далее используем коэффициент 0.6, 0.35, 0.25 
-- соответственно по значимости условного события ну и что бы результат был нагляднее взял промежуток с 2000 года 
-- из-за особенностей сгенерированных данных!  
SELECT CONCAT(first_name,' ',last_name) AS `Name` , ps.Post, lk.Like, ms.Messages, (ps.Post*0.6 + lk.Like*0.35 + ms.Messages*0.25) as Total, 'Период с 2000-01-01 по н.в.' as Time FROM users LEFT JOIN
(SELECT users.id as user1,  COUNT(posts.id) as `Post` FROM users LEFT JOIN posts ON users.id = posts.user_id AND posts.created_at BETWEEN "2000-01-01" AND now() GROUP BY 1) as ps on users.id = ps.user1 LEFT JOIN
(SELECT users.id as user2,  COUNT(likes.id) as `Like` FROM users LEFT JOIN likes ON users.id = likes.user_id AND likes.created_at BETWEEN "2000-01-01" AND now() GROUP BY 1) as lk on users.id = lk.user2 LEFT JOIN
(SELECT users.id as user3,  COUNT(messages.id) as `Messages` FROM users LEFT JOIN messages ON users.id = messages.from_user_id AND messages.created_at BETWEEN "2000-01-01" AND now() GROUP BY 1) as ms on users.id = ms.user3 ORDER BY Total;
-- Вывод:
-- Name               post like mess Total (post*0.6+like*0.35+mess*0.25)
-- Eliseo Schultz	   0	0	0	0.00
-- Clemens Anderson	   0	0	0	0.00
-- Samson Sawayn	   1	2	0	1.30
-- Veda Runolfsson	   0	4	0	1.40
-- Orie Moore	       2	1 	0	1.55

-- эти запросты для проверки правильности итогового запроса
SELECT CONCAT(u.first_name,' ',u.last_name) AS `Name`,  COUNT(p.id) as `Post` FROM users u LEFT JOIN posts p ON u.id = p.user_id AND p.created_at BETWEEN "2000-01-01" AND now() GROUP BY 1;
SELECT CONCAT(u.first_name,' ',u.last_name) AS `Name`,  COUNT(l.id) as `Like` FROM users u LEFT JOIN likes l ON u.id = l.user_id GROUP BY 1;
SELECT CONCAT(u.first_name,' ',u.last_name) AS `Name`,  COUNT(m.id) as `Messages` FROM users u LEFT JOIN messages m ON u.id = m.from_user_id GROUP BY 1;
SELECT * FROM posts WHERE user_id = 1;
SELECT * FROM likes WHERE user_id = 1;
SELECT * FROM messages WHERE from_user_id = 1;
SELECT * FROM users;

-- А это прошлый запрос из 6 урока теперь кажеться совсем корявым после JOIN хотя результаты одинаковые)))!!! 
SELECT 
	id,
	CONCAT(first_name, ' ', last_name) AS name,
    (select count(id) from posts where user_id = u.id and created_at BETWEEN "2000-01-01" AND now()) as posts,
    (select count(id) from likes where user_id = u.id and created_at BETWEEN "2000-01-01" AND now())  as likes,
    (select count(id) from messages where from_user_id = u.id and created_at BETWEEN "2000-01-01" AND now()) as messages,
    ((select count(id) from posts where user_id = u.id and created_at BETWEEN "2000-01-01" AND now())* 0.6) + 
    ((select count(id) from likes where user_id = u.id and created_at BETWEEN "2000-01-01" AND now())* 0.35) +
    ((select count(id) from messages where from_user_id = u.id and created_at BETWEEN "2000-01-01" AND now())* 0.25) as total,
    'период с 2010-01-01 по н.в.' as time_add
from users u
order by total;
USE vk;
-- ЗАДАНИЕ № 1 
-- Проанализировать какие запросы могут выполняться наиболее часто в процессе работы приложения и добавить необходимые индексы.
SHOW TABLES;

SELECT * FROM communities;
-- индекс для поле name так как скорее всего будет частый поиск по этому полю
CREATE INDEX communities_name_idx ON communities(name);

SELECT * FROM communities_users;
-- мне кажется в этой таблице индекс не нужен, если в дальнейшем возникнет необходимость то скорее всего будет
-- составной индекс по полям (community_id, user_id)

SELECT * FROM friendship; 
-- есть целесообразность создание составного индекса по полям user_id и акшутв_шв так как возможны часстые запросыс этой связкой
CREATE INDEX friendship_user_id_friendship_friend_id_idx ON friendship(user_id, friend_id);

SELECT * FROM friendship_statuses;
-- в этой таблице индекс ненужен есть смысл пересмотреть структуру БД и отказаться от данной таблицы и использовать ENUM

SELECT * FROM like_types;
-- аналогично предыдущему коментарию проще использовать ENUM и отказаться от данной таблицы

SELECT *FROM likes;
-- целесообразен индекс по двум столбцам кто поставил и чему поставил то есть по user_id и target_id
CREATE INDEX likes_user_id_likes_targe_id_idx ON likes (user_id, target_id);

SELECT * FROM media;
-- мне кажется тут имеет смысл создать индекс по столбцу по которым возможен частый поиск это filename
CREATE INDEX media_filename_idx ON media(filename);

SELECT * FROM media_types;
-- индекс тут не нужен возможно тоже имеет смысл пересмотреть в сторону использования ENUM

SELECT * FROM messages;
-- пожалуй тут имеет смысл два индекса один общий на двастолбца отправитель получатель и второй это заголовок
CREATE INDEX messages_from_user_id_messages_to_user_id_idx ON messages (from_user_id, to_user_id);
CREATE INDEX messages_header_idx ON messages (header);

SELECT * FROM posts;
-- целесообразен индекс по шапке поста
CREATE INDEX posts_header_idx ON posts (header);

SELECT * FROM profiles;
-- мне кажется тут индекс не нужен или в дальнейшем при использовании появится неоходимость и будут частые запросы на поиск 
-- возможно нужены будут два индекса по полям даты рождения и города

SELECT * FROM relation_statuses;
-- аналогично прошлым предложения есть смысл пересмотреть в сторону ENUM

SELECT * FROM relations;
-- врят ли данная таблица будет часто нагружаться поисковыми запросами поэтому если вдруг такие запросы возрастут то нужно смотреть 
-- по каким поля, скорее всего возможен составной индекс по user_id и relative_id
 
SELECT * FROM target_types;
-- индекс в данный таблице не нужен возможено тоже нужно пересмотреть в сторону ENUM

SELECT * FROM users;
-- в данной таблице я бы добавил три индекса один из них составной
CREATE INDEX users_first_name_users_last_name_idx ON users (first_name, last_name);
CREATE INDEX users_email_idx ON users (email);
CREATE INDEX users_phone_idx ON users (phone);

-- ******************************************************************************************************************
-- ЗАДАНИЕ № 2 
-- Задание на оконные функции. Построить запрос, который будет выводить следующие столбцы:
-- имя группы
-- среднее количество пользователей в группах
-- самый молодой пользователь в группе
-- самый пожилой пользователь в группе
-- общее количество пользователей в группе
-- всего пользователей в системе
-- отношение в процентах (общее количество пользователей в группе / всего пользователей в системе) * 100

SELECT * FROM communities;
SELECT * FROM communities_users;
select * from profiles;
select * from users;

-- Это было очень не просто но на третий день мучений пришло прозрение надеюсь решение правильное ну или очень надеюсь
-- что близко к правильному. Очень прикольные оконные функции ни одной групировки и сортировки зато столько статистики
-- выведено на JOIN и вложенных запросах даже не представляю какой чумавой запрос был бы!!!
-- Очень жду коментариев к этому заданию!!! 
FROM
	communities;

SELECT 
	DISTINCT communities.name,                                                                  -- имя группы
	COUNT(*) OVER() / (SELECT COUNT(id) FROM communities) AS AVG_user_in_group,                 -- среднее количество пользователей в группе
	MAX(profiles.birthday) OVER w AS Young_user,                                                -- самый молодой пользователь
	MIN(profiles.birthday) OVER w AS Old_user,                                                  -- самый старый пользователь
	COUNT(communities_users.user_id) OVER w AS COUNT_user_group,                                -- всего пользователей в группе
	(SELECT COUNT(*) FROM users) AS ALL_users,                                                  -- всего пользователей в системе
	COUNT(communities_users.user_id) OVER w / (SELECT COUNT(*) FROM users) * 100 AS `Group/All` -- отношение в процентах (общее количество пользователей в группе / всего пользователей в системе) * 100 
FROM

-- ***********************************************************************************************************
-- попробовал вывести дополнительно имена самого молодого и самого старого пользователя для последующей обработки 
-- надеюсь правильно
-- ***********************************************************************************************************
WITH dt AS (SELECT CONCAT(first_name,' ',last_name) FROM users JOIN profiles ON users.id = profiles.user_id)
SELECT 
	DISTINCT communities.name,                                                                  -- имя группы
	COUNT(*) OVER() / (SELECT COUNT(id) FROM communities) AS AVG_user_in_group,                 -- среднее количество пользователей в группе
	FIRST_VALUE(CONCAT(users.first_name,' ',users.last_name)) OVER(PARTITION BY communities_users.community_id ORDER BY profiles.birthday DESC) AS `Young`, -- если нужны id пользователей для последующей обработки
	MAX(profiles.birthday) OVER w AS Young_user,                                                -- самый молодой пользователь
	FIRST_VALUE(CONCAT(users.first_name,' ',users.last_name)) OVER(PARTITION BY communities_users.community_id ORDER BY profiles.birthday) AS `Old`,        -- если нужны id пользователей для последующей обработки
	MIN(profiles.birthday) OVER w AS Old_user,                                                  -- самый старый пользователь
	COUNT(communities_users.user_id) OVER w AS COUNT_user_group,                                -- всего пользователей в группе
	(SELECT COUNT(*) FROM users) AS ALL_users,                                                  -- всего пользователей в системе
	COUNT(communities_users.user_id) OVER w / (SELECT COUNT(*) FROM users) * 100 AS `Group/All` -- отношение в процентах (общее количество пользователей в группе / всего пользователей в системе) * 100 
FROM
	(communities_users 
	JOIN communities ON communities_users.community_id = communities.id
	JOIN profiles ON communities_users.user_id = profiles.user_id
	JOIN users ON users.id = profiles.user_id)
	WINDOW w AS (PARTITION BY communities_users.community_id); -- тут вынесение окнав эту строку наверное потеряла актуальность

-- ЗАДАНИЕ № 3 
-- (по желанию) Задание на денормализацию. Разобраться как построен и работает следующий запрос:
-- Найти 10 пользователей, которые проявляют наименьшую активность в использовании социальной сети.

-- запрос ищет все сумму всех отправленных сообщений ползователями, опубликованныйх media и поставленных
-- лайков и на основе сортировки от меньшего кбольшему ищет наименее активного пользователя.  
SELECT users.id,
COUNT(DISTINCT messages.id) + COUNT(DISTINCT likes.id) + COUNT(DISTINCT media.id) AS activity
FROM users
LEFT JOIN messages
ON users.id = messages.from_user_id
LEFT JOIN likes
ON users.id = likes.user_id
LEFT JOIN media
ON users.id = media.user_id
GROUP BY users.id
ORDER BY activity
LIMIT 10;

-- Правильно-ли он построен?
-- насколько я понял запрос построен правильно единственное что можно было бы добавить еще post. Я лично ещё в своём ДЗ 
-- добавлял коэфициенты, так как например пять отправленных сообщений, которые никто не видит или 5 постов имеют разную 
-- значимость активности и на основе такой более дифферинцированной статистики с коэффициентом можно более гибко настраивать 
-- нативную рекламу и прочие плюшки социальной сети(возможных друзей, музыку,видео, новости и т.д.)  

-- Какие изменения, включая денормализацию, можно внести в структуру БД
-- что бы существенно повысить скорость работы этого запроса?
--  Учитывая,  что запрос строиться по разным таблицам и их объединение не целесообразно то кроме индексов на столбцы которые 
-- сладываюся если они не PRIMARY и внешних ключей особо больше ничего на ум не приходит. Запрос который был на семинаре на 
-- сколько я помню считал определённые медиа категории (фото и т.д.) тогда тут возможно объединение таблицы media и media_types 
-- с и использование типа данных ENUM 






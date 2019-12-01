use vk;
-- Задание № 1 

-- По запросам добавить  или изменить особо нечего, но меня немного смутила система таблиц лаков. 
-- по сути достаточно сложная логика и мне кажется что было бы достаточно создать одну таблицу Likes(id, user_id, media_id, created_at)
-- где media_id ссылается на таблицу где храняться типы данных(фото, аудио, видео, пост и т.д.). Хотя это просто моё субъективное мнение.

-- Зажание № 2 Пусть задан некоторый пользователь. 
-- Из всех друзей этого пользователя найдите человека, который больше всех общался с нашим пользователем.

-- Логика решения следующая: мы берем пользователя условно с id = 1 например и делаем двыборку сообщений которые он 
-- отправил пользователям, сортируе по убыванию и выводим первую строчку. Далее объединяем эту выборку по горизонтали с 
-- выборкой где наш пользователь является получателем писем по той же логике групируем сотрируем по убывани и выводим также
-- одну строчку. Таким образом у нас таблица из двух строчек с наибольшим количеством отправленных и полученных сообщений 
-- условным пользователем. Думал как объединить эти две строки и посчитать сумму общего количества отправленных и полученных
-- сообщений, но кроме временной таблице опять ничего в голову не приходит.   

(SELECT 
	(SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE id = from_user_id) AS `from`,
	(SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE id = to_user_id) AS `to`,
 	COUNT(*) AS total_messages 
FROM 
	messages
WHERE 
	from_user_id = 1 
GROUP BY 
	to_user_id 
ORDER BY 
	total_messages DESC LIMIT 1) 
UNION		
(SELECT 
	(SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE id = from_user_id) AS `from`,
	(SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE id = to_user_id) AS `to`,
 	COUNT(*) AS total_messages 
FROM 
	messages
WHERE 
	to_user_id = 1 
GROUP BY 
	from_user_id 
ORDER BY 
	total_messages DESC LIMIT 1);

-- здесь привожу более правильный запрос с теми кто находиться в друзьях у нашего условного пользователя id=1 и дружба подтверждена  
-- но из-за нулевых значений так как требует более тщательная генерации данных оставляю выше выборку
-- или я в чемто ошибся?
(SELECT 
	(SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE id = from_user_id) AS `from`,
	(SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE id = to_user_id) AS `to`,
 	COUNT(*) AS total_messages 
FROM 
	messages
WHERE 
	from_user_id = 1 AND to_user_id in (SELECT friend_id from friendship WHERE user_id = 1 and status_id = 2)
GROUP BY 
	to_user_id 
ORDER BY 
	total_messages DESC LIMIT 1)
UNION
(SELECT 
	(SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE id = from_user_id) AS `from`,
	(SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE id = to_user_id) AS `to`,
 	COUNT(*) AS total_messages 
FROM 
	messages
WHERE 
	to_user_id = 1 AND from_user_id in (SELECT user_id from friendship WHERE friend_id = 1 and status_id = 2)
GROUP BY 
	from_user_id 
ORDER BY 
	total_messages DESC LIMIT 1);

-- Задание №3 
-- Подсчитать общее количество лайков, которые получили 10 самых молодых пользователей.

-- решал изходя из того что target_id это связь с id в таблице media иначе не понятно какрешать задачу
SELECT
   user_id,
  (SELECT CONCAT(first_name, ' ', last_name) from users WHERE id = p.user_id) AS name, 
  birthday, 
  (SELECT COUNT(target_id) FROM likes WHERE target_id in (SELECT id FROM media WHERE user_id = p.user_id)) AS total_like 
FROM profiles p
ORDER BY birthday DESC
LIMIT 10;
-- проверил вроде результат сходится
SELECT id from media WHERE user_id IN (939,108,596,929,700,299,696,395,497,208);
SELECT target_id, COUNT(*) from likes WHERE target_id IN (6,44,57,72,80) GROUP BY target_id;
 
SELECT * FROM profiles ORDER BY birthday DESC LIMIT 10;
SELECT * from users WHERE id in (939,108,596,929,700,299,696,395,497,208); 
-- попробовал еще через таблицу users результат совпадает но почему то время отработки большое?
SELECT 
CONCAT(first_name, ' ',  last_name) AS name,
(SELECT birthday FROM profiles WHERE user_id = id) AS birthday,
(SELECT COUNT(target_id) FROM likes WHERE target_id IN (SELECT id FROM media WHERE user_id = u.id)) AS total_likes
FROM users u
ORDER BY birthday DESC LIMIT 10;

-- если чесно какая то чихарда с таблицей Likes и её логикой мне кажется проще было сделать таблицу из четырёх столбцов
-- id, user_id(кто поставил лайк), media_id(какому посту поставил лайк в media собраны все сущности), created_at (когда поставил)
-- этого более чем достаточно что бы реализовать систему лайков на мой взгляд, а так много дублирующих не определенных данных

-- Задание № 4 
-- Определить кто больше поставил лайков (всего) - мужчины или женщины?
SELECT 
	IF((SELECT sex from profiles WHERE user_id= l.user_id) = 'm', 'man', 'woman') as sex, 
    COUNT(*) total_likes 
FROM 
	likes l 
GROUP BY 
	sex 
ORDER BY total_likes DESC;

-- Задание № 5 
-- Найти 10 пользователей, которые проявляют наименьшую активность в использовании социальной сети.

-- Оценивать будем по количеству размещенных постов, поставленных лайков и отправленных сообщений за последний год(месяц, день и т.д я взял с 2010 т.к. данные 
-- сгенерированы не очень удачно и в случае если взять за 1 год почти одни 0). Считае, что единица активности это одно действие пользователя за указанный период,
-- при этом вводим коэфицент активности по значимостито есть 60% это пост, 35% лайк и 25% сообщение. Далее делаем три выборки по постам, лайкам и сообщениям
-- в случае с сообщениями берем только отправленные пользователем (входящие не влияют на активность) считаем количество указанных сущностей связанных с
-- конкретным пользователем и за указанный промежуток времени, а также рузультирующим столбцом будет сумма первых трех. И сортируем по убывани
-- таки образом у нас есть результат когда один пост считается более активным чем два сообщения отправленных кому то так как пост видят все
-- а сообщения отдельно взятые люди. Процентовку можно менять. 
-- Очень интересует ваше мнения насчёт решения оно слишком грамоздкое на мой взгляд
-- и еще почему-то не получается в результирующем столбце например просто применить действие к именам столбцов что значительно сократило бы запись
-- приходится дублировать строки на сколько это плохая практика?

select 
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



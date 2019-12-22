-- Задане №1 Доработать данные
USE vk;
SELECT * FROM users LIMIT 10;
-- Данные удовлетворительные
-- '1', 'Sonny', 'Schuppe', 'nelle.strosin@example.net', '05887170693', '1996-12-20 09:39:01', '1987-08-08 18:55:11'

SELECT * FROM profiles LIMIT 10;
-- Данные приемлемы  с учётом того что пользователей 1000 foto_id тоже 1000
-- '1', 'w', '2018-02-13', 'East Marilouport', '412'

SELECT * FROM messages LIMIT 50;
SELECT * FROM messages WHERE from_user_id = to_user_id LIMIT 50;
UPDATE messages SET from_user_id = from_user_id + 1 WHERE from_user_id = to_user_id;
-- '1', '42', '41', 'Consequatur nemo ...', '1', '0', '1979-01-16 17:05:54'
-- данные приемлемы но решил с вашими рекомендациями убрать письма самому себе

-- по вашей же подзказке доработал структуру путем экспериментов пришел к выводу, что для получения данных
-- когда пользователи имеют по несколько сообщений друг от друга можно использовать от рандом 100 для отправителя 
-- и рандом 20 для получателя теперь можно делать выборки по наибольшему общению, а также убрал нулевые значения id у столбцов
-- получившиеся в результате работы рандома хотя наверное как то можно исключить их при выполнении самой функции?
UPDATE messages SET 
	to_user_id = FLOOR(1+(rand()*100)),
    from_user_id = FLOOR(1+(rand()*20));
-- UPDATE messages SET to_user_id = 100 WHERE to_user_id = 0;    FLOOR(1+(rand()*100)) прибавление 1 убирает нули
-- UPDATE messages SET	from_user_id = 20 WHERE from_user_id = 0;
-- ПРОШУ СОВЕТА!!! смотрим кто кому больше всего отправил сообщений. Разбирался сам сэтой командой пожалуйста скажите правильно или нет?
SELECT from_user_id as sender, to_user_id as receive, COUNT(*) as total_messeg FROM messages GROUP BY from_user_id, to_user_id ORDER BY COUNT(from_user_id) DESC;

SELECT * from media LIMIT 50;
-- доработал по материалам семинара. metadata имел тип longtext но почемуто CHANGE не сработал изменил через modify
ALTER TABLE media MODIFY metadata JSON;
-- далее добавил данные в поле metadata
UPDATE media SET metadata = CONCAT('{"',filename,'":"',size,'"}');
-- немного хаоса в столбцы media_type_id и user_id для реализма
UPDATE media SET 
	media_type_id = (SELECT id FROM media_types ORDER BY RAND() LIMIT 1),
    user_id = FLOOR(1+(RAND()*100));
-- генерируем медия для все 1000 пользователей
UPDATE media SET 
    user_id = FLOOR(1+(RAND()*1000));

SELECT * FROM media_types;
INSERT INTO media_types VALUE (5, 'photo');
UPDATE media SET media_type_id = (SELECT id FROM media_types ORDER BY RAND() LIMIT 1);
-- добавил фото и покоректировал таблицу media
-- 	3	audio	2	file	4	text	1	video   5   photo

SELECT * from friendship LIMIT 50;
-- убрал дружбу самим с собой
UPDATE friendship SET user_id = user_id + 1 WHERE user_id = friend_id;

SELECT * FROM friendship_statuses;
-- данные коректные вводил вручную
-- 	2	approved	3	declined	1	requsted	4	unfriended

SELECT * FROM communities;
-- данные коректные 
-- 	26	Bahringer-Berge;	39	Boehm Inc;	42	Bosco-Dickens

SELECT * FROM communities_users;
-- данные коректные
-- 	1	1;	1	51;	2	2

-- ЗАДАНИЕ № 2 
-- пердложение по созданию таблицы лайков. кто лайкнул и что лайкнул из таблицы media впринципе навернок и всё
DROP TABLE IF EXISTS likes;
CREATE TABLE likes (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    media_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at DATETIME DEFAULT NOW()
);

-- Задание № 3
-- Подобрать сервис-образец для курсовой работы
-- Я решил реализовать свой придуманый проект его суть слудующая:
-- Курсовой проект "Арбитр". 
-- Портал который позволяет физическим и юридическим лицам заключать безопасные сделки. 
-- Логика работы:
-- 	- пользователи регистрируются на портале по номеру телефона и заполняют свой профиль;
-- 	- любой пользователь может выступать в роли заказчика или исполнителя;
-- 	- заказчик создает форму заказа, с описанием сроков и условий исполнения (покупка и отправка товара, услуга и т.д.) 
-- 	  и отправляет запрос на исполнение исполнителю по email, SMS-ссылкой и другие варианты;
-- 	- исполнитель принимает условия или вностит дополнения замечания;
-- 	- после согласования контракта заказчик вносит платёж на площадку до выполнения сроков договора;
-- 	- по исполнению оба подтверждают выполнение и исполнитель получает платёж;
-- 	- в случае возникновения спора с любой строны подаеётся соответствующая форма и приводятся доказательства 
-- 	  фото, видео, текстовое описание;
-- 	- по завершению спора выносится решение с удовлетворением полностью или частичным спора и его условий. 
-- По сути этоаналог безопасной сделки на Авито или Юле, однако в данных сервисах не учтено ряд моментов такие как 
-- снижение цены например работа с юр лицами и многое другое. 

-- Задание № 4
-- Доработать структуру согласно предложениям команды
-- в соответствии с предложениями внес изменения в таблицы
-- !!!далее можно не смотреть идёт доработка БД согласно предложений на семинаре!!!

ALTER TABLE users ADD COLUMN is_banned BOOL AFTER phone;
ALTER TABLE users ADD COLUMN is_active BOOL DEFAULT TRUE AFTER is_banned;
SELECT * FROM users LIMIT 50;
CREATE TEMPORARY TABLE val(val BOOL);
INSERT INTO val VALUES (TRUE), (FALSE);
UPDATE users SET is_banned = (SELECT val FROM val ORDER BY RAND() LIMIT 1);
DROP TABLE IF EXISTS val;
UPDATE users SET is_active = FALSE WHERE id IN (45, 431, 255, 2, 57, 159, 411, 332, 401,17);

SELECT * FROM friendship_statuses;

ALTER TABLE communities ADD COLUMN created_at DATETIME DEFAULT NOW() AFTER name;
ALTER TABLE communities ADD COLUMN is_closed BOOLEAN AFTER created_at;
ALTER TABLE communities ADD COLUMN closed_at TIMESTAMP AFTER is_closed;
ALTER TABLE communities MODIFY user_id INT UNSIGNED;
CREATE TEMPORARY TABLE val(val BOOL);
INSERT INTO val VALUES (TRUE), (FALSE);
UPDATE communities SET user_id = (SELECT id FROM users ORDER BY RAND() LIMIT 1),
	created_at = (SELECT created_at FROM users ORDER BY RAND() LIMIT 1),
    is_closed = (SELECT val FROM val ORDER BY RAND() LIMIT 1),
    closed_at = (SELECT created_at FROM profiles ORDER BY RAND() LIMIT 1);
ALTER TABLE communities CHANGE user_id user_admin_id INT UNSIGNED;
SELECT * FROM communities;
UPDATE communities SET closed_at = NULL;
UPDATE communities SET closed_at = NOW() WHERE is_closed IS TRUE;
DROP TABLE IF EXISTS val;

ALTER TABLE communities_users ADD COLUMN is_banned BOOLEAN AFTER user_id;
ALTER TABLE communities_users ADD COLUMN is_admin BOOLEAN AFTER user_id;

CREATE TEMPORARY TABLE val(val BOOL);
INSERT INTO val VALUES (TRUE), (FALSE);
UPDATE communities_users SET is_banned = (SELECT val FROM val ORDER BY RAND() LIMIT 1);
UPDATE communities_users SET is_admin = (SELECT val FROM val ORDER BY RAND() LIMIT 1);
DROP TABLE IF EXISTS val;
SELECT * FROM communities_users;

ALTER TABLE messages ADD COLUMN header VARCHAR(255) AFTER to_user_id;
UPDATE messages SET header = SUBSTRING(body, 1, 50);

ALTER TABLE messages ADD COLUMN attached_media_id INT UNSIGNED AFTER body;
UPDATE messages SET attached_media_id = (SELECT id FROM media WHERE user_id = from_user_id LIMIT 1);

DROP TABLE IF EXISTS relations;
CREATE TABLE relations (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    relative_id INT UNSIGNED NOT NULL,
    relative_status_id INT UNSIGNED NOT NULL
);

DROP TABLE IF EXISTS relation_statuses;
CREATE TABLE relation_statuses(
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100)
);

INSERT INTO relation_statuses (name) VALUES
('son'),
('daughter'),
('mother'),
('father'),
('wife'),
('husband')
; 

INSERT INTO relations SELECT
id, 
FLOOR(1 + (RAND() * 100)),
FLOOR(1 + (RAND() * 100)),
FLOOR(1 + (RAND() * 6))
FROM users;

TRUNCATE relations;

INSERT INTO relations SELECT
id, 
FLOOR(1 + (RAND() * 100)),
FLOOR(1 + (RAND() * 100)),
FLOOR(1 + (RAND() * 6))
FROM relation_statuses;

SELECT * FROM relations;
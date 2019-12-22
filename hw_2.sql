-- Создаем базу данных example

create database if not exists example;
use example;
drop table if exists users;
create table users(
    id SERIAL primary key,
    name varchar(100)
) COMMENT = 'Таблица users';

INSERT INTO users VALUES(0,'Pavel');
INSERT INTO users VALUES(NULL,'Pavel');
INSERT INTO users (name) VALUES('Pavel');
/* Создание дампа в консоле: 
 * mysqldump example > C:\Users\Device\example_dump.sql
 * Разворачиваем дамп:
 * mysql example < C:\Users\Device\example_dump.sql
 */

/*Создаем dump первыч 100 записей
 *mysqldump --where="true limit 100" mysql --tables help_keyword > C:\Users\Device\mysql_help_keyword_dump.sql
 */
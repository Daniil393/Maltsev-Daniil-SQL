-- удаление всего
drop table if exists cms.users cascade;
drop table if exists cms.articles cascade;
drop table if exists cms.comments cascade;

drop user if exists report;
drop user if exists carol;
drop user if exists alice;
drop user if exists james;

drop schema if exists cms;

drop role if exists app_user;
drop role if exists admin;
drop role if exists editor;
drop role if exists viewer;
drop role if exists reporting_user;



create schema cms;
alter schema cms owner to postgres;

-- Таблица пользователей
create table cms.users (
    id serial primary key,
    username text unique not null,
    email text unique not null,
    role text not null check (role in ('admin', 'editor', 'viewer')),
    created_at timestamp default now()
);

-- Таблица статей
create table cms.articles (
    id serial primary key,
    author_id int references cms.users(id),
    title text not null,
    content text not null,
    is_published boolean default false,
    created_at timestamp default now()
);

-- Таблица комментариев
create table cms.comments (
    id serial primary key,
    article_id int references cms.articles(id),
    user_id int references cms.users(id),
    text text not null,
    created_at timestamp default now()
);

-- Роли

-- Базовая роль, через неё назначаются все привилегии
create role app_user;

create role admin;
create role editor;
create role viewer;
create role reporting_user;

-- Пользователи
create user james with password '4nGTEFeA4E';
grant admin to james;

create user carol with password 'xFdxEKCXR4';
grant editor to carol;

create user alice with password 'LgZA2lYk3G';
grant viewer to alice;

create user report with password 'QbBxM8NWKi';
grant reporting_user to report;

-- Базовые права на схему
grant usage on schema cms to app_user;

-- Привилегии

-- ADMIN: полный доступ
grant select, insert, update, delete on all tables in schema cms to admin;
grant all privileges on all sequences in schema cms to admin;

-- EDITOR
grant select on cms.users to editor;                    -- только чтение пользователей
grant select, insert, update on cms.articles to editor; -- может писать только свои статьи (через RLS)
grant select, insert on cms.comments to editor;         -- комментарии (через RLS)

-- VIEWER — только чтение
grant select on all tables in schema cms to viewer;

-- REPORTING USER — доступ к ограниченным столбцам

-- Только аналитические поля статей
grant select(id, is_published, created_at) on cms.articles to reporting_user;

-- Только аналитические поля комментариев
grant select(id, article_id, created_at) on cms.comments to reporting_user;

-- Полный запрет на таблицу пользователей
revoke all on cms.users from reporting_user;

-- RLS (Row-Level Security)

-- Статьи
alter table cms.articles enable row level security;

-- Viewer может только читать опубликованные статьи
create policy viewer_only_published on cms.articles for select to viewer using (is_published = true);

-- Reporting_user может только читать опубликованные статьи и только разрешённые столбцы
create policy reporting_only_puplished on cms.articles for select to reporting_user using (is_published = true);

-- Editor может видеть всё
create policy editor_select_all on cms.articles for select to editor using (true);

-- Editor обновляет только свои статьи
create policy editor_update_own on cms.articles for update to editor
using (author_id = (select id from cms.users where username = current_user))
with check (author_id = (select id from cms.users where username = current_user));

-- Комментарии
alter table cms.comments enable row level security;

-- viewer: читать все строки таблицы cms.comments
create policy viewer_comments on cms.comments for select to viewer using (true);

-- Reporting_user: RLS для аналитики
create policy reporting_comments on cms.comments for select to reporting_user using (true);

-- Editor: читать всё
create policy editor_comments_select on cms.comments for select to editor using (true);

-- Editor может писать только от своего имени
create policy editor_comments_insert on cms.comments for insert to editor
with check (user_id = (select id from cms.users where username = current_user));

-- Default Privileges
alter default privileges in schema cms grant select on tables to viewer;
alter default privileges in schema cms grant select, insert, update on tables to editor;
alter default privileges in schema cms grant select, insert, update, delete on tables to admin;



-- Пример данных
insert into cms.users(username, email, role) values
('james', 'JamesOlson@mail.com', 'admin'),
('carol', 'CarolHodges@mail.com', 'editor'),
('alice', 'AliceMendoza@mail.com', 'viewer');

insert into cms.articles(author_id, title, content, is_published) values
(1, 'Admin Article', 'Admin content', true),
(2, 'Editor Draft', 'Editor content', false),
(2, 'Editor Published', 'Editor content published', true);

insert into cms.comments(article_id, user_id, text) values
(1, 3, 'Great article!'),
(3, 2, 'Needs some edits');























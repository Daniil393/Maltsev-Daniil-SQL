-- 1) Структура базы данных

create table readers (
    reader_id serial primary key,
    last_name text not null,
    first_name text not null,
    patronymic text not null,
    address text not null
);

create table books (
    book_id serial primary key,
    author text not null,
    title text not null,
    pub_year integer not null,
    deposit numeric(10, 2) not null
);

create table subscription (
    issue_id serial primary key,
    reader_id integer not null references readers(reader_id),
    book_id integer not null references books(book_id),
    issue_date date not null,
    return_date date
);

-- 2) Представление без идентификаторов

create view subscription_view as
    select
         r.last_name,
        r.first_name,
        r.patronymic,
        r.address,
        b.author,
        b.title,
        b.pub_year,
        b.deposit,
        s.issue_date,
        s.return_date
    from subscription s
        join readers r on s.reader_id = r.reader_id
        join books   b on s.book_id  = b.book_id;

-- 3) Триггерные функции

-- 3.1) INSERT: добавляет новые reader/book при необходимости, затем вставляет запись в subscription

create or replace function trg_subscription_view_ins()
returns trigger
language plpgsql
as $$
    declare
        v_reader_id integer;
        v_book_id integer;

    begin
        -- Находим существующего читателя (один поиск — один раз)
        select reader_id into v_reader_id from readers
        where last_name = new.last_name
        and first_name = new.first_name
        and patronymic = new.patronymic
        and address = new.address;

        -- Если нет - создаем
        if v_reader_id is null then
            insert into readers(last_name, first_name, patronymic, address)
            values (new.last_name, new.first_name, new.patronymic, new.address)
            returning reader_id into v_reader_id;
        end if;

        -- Находим книгу
        select book_id into v_book_id from books
        where author = new.author
        and title = new.title
        and pub_year = new.pub_year
        and deposit = new.deposit;

        -- Если нет - создаем
        if v_book_id is null then
            insert into books(author, title, pub_year, deposit)
            values (new.author, new.title, new.pub_year, new.deposit)
            returning book_id into v_book_id;
        end if;

        -- Вставляем запись в связку
        insert into subscription(reader_id, book_id, issue_date, return_date)
        values (v_reader_id, v_book_id, new.issue_date, new.return_date);

        return null;

end;
$$;

-- 3.2) UPDATE: обновляет запись в связке

create or replace function trg_subscription_view_upd()
returns trigger
language plpgsql
as $$
    declare
        v_reader_id integer;
        v_book_id integer;

    begin
        -- Ищем идентификаторы по OLD-данным:
        select reader_id into v_reader_id from readers
        where last_name = old.last_name
        and first_name = old.first_name
        and patronymic = old.patronymic
        and address = old.address;

        select book_id into v_book_id from books
        where author = old.author
        and title = old.title
        and pub_year = old.pub_year
        and deposit = old.deposit;

        update subscription
        set issue_date = new.issue_date,
            return_date = new.return_date
        where reader_id = v_reader_id
        and book_id = v_book_id
        and issue_date = old.issue_date;

        return null;
end;
$$;

-- 3.3) DELETE: удаляет запись из связки

create or replace function trg_subscription_view_del()
returns trigger
language plpgsql
as $$
    declare
        v_reader_id integer;
        v_book_id integer;

    begin
        -- Ищем идентификаторы по OLD-данным:
        select reader_id into v_reader_id from readers
        where last_name = old.last_name
        and first_name = old.first_name
        and patronymic = old.patronymic
        and address = old.address;

        select book_id into v_book_id from books
        where author = old.author
        and title = old.title
        and pub_year = old.pub_year
        and deposit = old.deposit;

        delete from subscription
        where reader_id = v_reader_id
        and book_id = v_book_id
        and issue_date = old.issue_date;

        return null;
end;
$$;

-- 4) Создание триггеров
create trigger subscription_view_ins_trg instead of insert on subscription_view for each row execute function trg_subscription_view_ins();
create trigger subscription_view_upd_trg instead of update on subscription_view for each row execute function trg_subscription_view_upd();
create trigger subscription_view_del_trg instead of delete on subscription_view for each row execute function trg_subscription_view_del();

-- 5) Тестирование
insert into subscription_view (last_name, first_name, patronymic, address, author, title, pub_year, deposit, issue_date, return_date)
values ('Иванов', 'Тимофей', 'Кириллович', 'Москва', 'Лев Толстой', 'Война и мир', 1869, 500,
 '2025-12-22', null);
select * from readers;
select * from books;
select * from subscription;


update subscription_view set return_date = '2025-12-25' where last_name = 'Иванов' and title = 'Война и мир';
select * from subscription;


delete from subscription_view where last_name = 'Иванов' and title = 'Война и мир';
select * from subscription;

-- Удаление
drop trigger if exists subscription_view_ins_trg on subscription_view;
drop trigger if exists subscription_view_upd_trg on subscription_view;
drop trigger if exists subscription_view_del_trg on subscription_view;

drop function if exists trg_subscription_view_ins() cascade;
drop function if exists trg_subscription_view_upd() cascade;
drop function if exists trg_subscription_view_del() cascade;

drop view if exists subscription_view;

drop table if exists subscription;
drop table if exists readers;
drop table if exists books;
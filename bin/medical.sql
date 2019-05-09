pragma foreign_keys = on;
begin transaction;
drop trigger if exists dose_after_insert;
drop trigger if exists dose_after_update;
drop trigger if exists dose_after_delete;
drop table if exists doseft;
drop table if exists dose;
drop table if exists medication;

create table medication (
    "name" text primary key not null,
    "comment" text
);

create table dose (
    "id" integer primary key not null,
    "datetime" integer not null default (datetime(CURRENT_TIMESTAMP,'localtime')) check (datetime(datetime) is not null),
    "name" text not null references medication(name),
    "comment" text not null default ''
);


--create virtual table doseft using fts4(content="dose", name, comment);
create virtual table doseft using fts5(docid, name, comment);

create trigger dose_after_insert after insert on dose
begin
    insert into doseft(docid, name, comment) values(new.id, new.name, new.comment);
end;

create trigger dose_after_update after update on dose
begin
    update doseft set docid = new.id, name = new.name, comment = new.comment where docid = old.id;
end;

create trigger dose_after_delete after delete on dose
begin
    delete from doseft where docid = old.id;
end;

--delete from sqlite_sequence;

.import /tmp/medication.dat medication
.import /tmp/dose.dat dose

commit;

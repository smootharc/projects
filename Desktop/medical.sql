pragma foreign_keys=off;
begin transaction;
drop table if exists weight;
drop table if exists dose;
drop table if exists alcohol;
drop table if exists medication;
drop table if exists prescription;

create table weight (
    "id" integer primary key not null,
    "date" integer not null default (current_date),
    "time" integer not null default (current_time),
    "pounds" real not null,
    "comment" text
);

create table dose (
    "id" integer primary key not null,
    "date" integer not null default (current_date),
    "time" integer not null default (current_time),
    "name" text not null,
    "comment" text
);

create table medication (
    "id" integer primary key not null,
    "name" text not null,
    "comment" text
);

create table prescription (
    "id" integer primary key not null,
    "rx" text not null,
    "date" integer not null default (current_date),
    "comment" text
);

create table alcohol (
    "id" integer primary key not null,
    "date" integer not null default (current_date),
    "name" text not null,
    "ml" text
);

delete from sqlite_sequence;
.import weight.dat weight
.import dose.dat dose
.import alcohol.dat alcohol
insert into medication ( name ) select distinct name from dose;
commit;

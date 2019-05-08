#!/usr/bin/python

import click
import sqlite3
import os
import datetime
import tabulate
from prompt_toolkit import prompt

dbfile = os.path.expanduser("~/Documents/.medical.db")

db = sqlite3.connect(dbfile)

db.execute("pragma foreign_keys = on")

db.row_factory = sqlite3.Row

cursor = db.cursor()

@click.group()
#@click.pass_context
def dose():
    pass
#    ctx.ensure_object(dict)
#    click.echo(ctx.invoked_subcommand)

@dose.command()
@click.argument('medication')
@click.argument('date', required=False, type=click.DateTime())
@click.option('--comment', "-c", default='')
def add(medication, date, comment):
    if date == None:
        date = datetime.datetime.now()
    sql = '''insert into dose (name, datetime, comment) values( ?, ?, ?)'''
    try:
        with db:
            result = db.execute(sql,(medication, date, comment))
            if result.rowcount == 0:
                raise sqlite3.Error
    except sqlite3.Error as e:
        click.echo(f'\nDatabase error: {e}\n')
        # click.echo("Failed to add dose.")


@dose.command()
@click.argument('id', type=int)
def edit(id):
    sql = '''select name, datetime, comment from dose where id = ?'''
    cursor.execute(sql, (id,))
    dose = cursor.fetchone()
    ( name, datetime, comment ) = dose
    
    click.echo(f"Editing dose {id}")
    name = prompt("Name: ", default=name)
    datetime = prompt("Date Time: ", default=datetime)
    comment = prompt("Comment: ", default=comment)
    
    sql = "update dose set name = ?, datetime = datetime(?), comment = ? where id = ?"

    try:
        with db:
            db.execute(sql, (name, datetime, comment, id))
    except sqlite3.Error as e:
        click.echo(f'Update error: {e}')
   

@dose.command()
@click.argument('id', type=int)
def remove(id):
    sql = 'delete from dose where id = ?'
    try:
        with db:
            deleted = db.execute(sql,(id,))
            if deleted.rowcount == 0:
                raise sqlite3.Error
    except sqlite3.Error:
        click.echo(f'\nRemoval of dose {id} failed.\n')
        exit(1)
    
    click.echo(f'\nRemoved dose {id}.\n')


@dose.command()
@click.argument('search_string')
@click.argument('start_time', required=False, type=click.DateTime())
@click.argument('end_time', required=False  , type=click.DateTime())
#@click.pass_context
def search(search_string, start_time, end_time):
    """This is some help text"""
    if start_time is None:
        start_time = datetime.datetime.now() - datetime.timedelta(weeks=52)
    if end_time is None:
        end_time = datetime.datetime.now()
    
    sql = '''select date(datetime) as date, time(datetime) as time, id, name, comment from dose where id in 
            ( select docid from doseft where doseft match ? ) and datetime between ? and ? order by datetime'''

    # search_result = cursor.execute(sql, (search_string, start_time, end_time))
    search_result = db.execute(sql, (search_string, start_time, end_time))

    if search_result.rowcount == 0:
        exit(0)

    last_date = None
    rows_to_print = []
    for row in search_result:
        if last_date == row['date']:
            date = ''
        else:
            date = row['date']
            last_date = row['date']
            rows_to_print.append([""])

        rows_to_print.append([date, row['time'], row['id'], row['name'], row['comment']])
        
    # print(tabulate.tabulate(rows_to_print, headers=("Date", "Time", "Id", "Name", "Comment"),tablefmt="plain"))
    print(tabulate.tabulate(rows_to_print, tablefmt="plain"))

@dose.command()
@click.argument('medication')
@click.argument('start_time', required=False, type=click.DateTime())
@click.argument('end_time', required=False, type=click.DateTime())
def count(medication, start_time, end_time):
    if start_time == None:
        start_time = datetime.datetime.now() - datetime.timedelta(days=30)
    if end_time == None:
        end_time = datetime.datetime.now()

    sql = '''select count(*) as count from dose where name = ? and datetime between ? and ?'''
    doses = db.execute(sql, (medication, start_time, end_time)).fetchone()[0]
    # doses.Row['count']

    days = (end_time - start_time).total_seconds()
    days = days/24/60/60

    if days <= 0:
        click.echo("\nStart time is later than end time.\n")
        exit(1)
    dosespd = doses/days
    # dosespd = ''

    click.echo('')
    click.echo(f'Medication: {medication}')
    click.echo(f'      From: {start_time.isoformat(sep=" " , timespec="minutes")}')
    click.echo(f'        To: {end_time.isoformat(sep= " ", timespec="minutes")}')
    click.echo(f'     Doses: {doses}')
    click.echo(f'      Days: {days:.2f}')
    click.echo(f' Doses/Day: {dosespd:.2f}')
    click.echo('')
    

@dose.command()
@click.argument('start_time', required=False, type=click.DateTime())
@click.argument('end_time', required=False  , type=click.DateTime())
def list(start_time, end_time):
    if start_time is None:
        start_time = datetime.datetime.now() - datetime.timedelta(weeks=8)
    if end_time is None:
        end_time = datetime.datetime.now()
    
    sql = '''select date(datetime) as date, time(datetime) as time, id, name, comment from dose where datetime between ? and ? order by datetime'''

    search_result = cursor.execute(sql, (start_time, end_time))

    last_date = None
    rows_to_print = []
    for row in search_result:
        if last_date == row['date']:
            date = ''
        else:
            date = row['date']
            last_date = row['date']
            rows_to_print.append([""])

        rows_to_print.append([date, row['time'], row['id'], row['name'], row['comment']])  
  
# print(tabulate.tabulate(rows_to_print, headers=("Date", "Time", "Id", "Name", "Comment"),tablefmt="plain"))
    print(tabulate.tabulate(rows_to_print, tablefmt="plain"))

@dose.command()
# @click.option("--comment", "-c", nargs=1, default='')
@click.option('--add', '-a', is_flag=True)
def medications(add):
    if not add:
        meds = db.execute("select * from medication")
        print("")
        print(tabulate.tabulate(meds, headers=["Name","Comment"]))
        print("")
    else:
        medication = prompt("Enter the medication name: ")
        if medication == '':
            click.echo("\nMust enter a something.\n")
            exit(1)
        comment = prompt(f'Enter a comment for {medication}: ')
        sql = '''insert into medication (name, comment) values( ?, ? )'''
        try:
            with db:
                result = db.execute(sql, (medication, comment ))
                if result.rowcount == 0:
                    raise sqlite3.Error
                click.echo(f'Added {medication} to medication table')
        except sqlite3.Error:
            click.echo(f'Failed to ad medication.')
            exit(1)
        

if __name__ == '__main__':
    dose()
#    dose(obj={})

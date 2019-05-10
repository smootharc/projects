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

def print_rows(rows):
    
    last_date = None

    rows_to_print = []

    for row in rows:

        if last_date == row['date']:

            date = ''

        else:

            date = row['date']

            last_date = row['date']

            rows_to_print.append([""])

        rows_to_print.append([date, row['time'], row['id'], row['name'], row['comment']])
  
    rows_to_print.append([""])

    #click.echo(tabulate.tabulate(rows_to_print, tablefmt="plain"))
    print(tabulate.tabulate(rows_to_print, tablefmt="plain"))

@click.group()
#@click.pass_context
def dose():
    pass
#    ctx.ensure_object(dict)
#    click.echo(ctx.invoked_subcommand)

@dose.command()
@click.argument('medication')
@click.argument('date', required=False, type=click.DateTime())
@click.option('--comment', "-c")
#@click.argument('comment', required=False)
def add(medication, date, comment):

    if date == None:

        date = datetime.datetime.now()
    
    if comment == None:

        comment = ''

    sql = '''insert into dose (name, datetime, comment) values( ?, ?, ?)'''

    try:

        with db:

            cursor = db.cursor()

            cursor.execute(sql,(medication, date, comment))

            click.echo(f"\nAddition succeeded.  Dose id is {cursor.lastrowid}\n")

    except sqlite3.Error as e:

        click.echo(f'\nDatabase error: {e}\n')


@dose.command()
@click.argument('id', type=int)
def edit(id):

    sql = '''select name, datetime, comment from dose where id = ?'''

    dose = db.execute(sql, (id,)).fetchone()
    
    if not dose:

        print(f"\nDose {id} not found.\n")

        exit(1)
        
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

        click.echo(f'Record edit failed {e}')
        
    click.echo("Record edit succeeded.")

@dose.command()
@click.argument('id', type=int)
def remove(id):

    '''Remove a dose.'''

    sql = 'delete from dose where id = ?'

    try:

        with db:

            deleted = db.execute(sql,(id,))

            db.commit

            if deleted.rowcount == 0:

                click.echo(f"\nRemoval of Dose {id} failed.\n")

            else:

                click.echo(f'\nRemoval of Dose {id} succeeded.\n')                   

    except sqlite3.Error as e:

        click.echo(e)

        exit(1)


@dose.command()
@click.argument('search_string')
@click.argument('start_time', required=False, type=click.DateTime())
@click.argument('end_time', required=False  , type=click.DateTime())
#@click.pass_context
def search(search_string, start_time, end_time):

    """Case insensitive search of dose names and comments."""

    if start_time is None:

        start_time = datetime.datetime.now() - datetime.timedelta(weeks=52)

    if end_time is None:

        end_time = datetime.datetime.now()
    
    sql = '''select date(datetime) as date, time(datetime) as time, id, name, comment from dose 
            where id in ( select docid from doseft where doseft match ? ) 
            and datetime between ? and ? order by datetime'''

    try:

        search_result = db.execute(sql, (search_string, start_time, end_time)).fetchall()
    
    except sqlite3.OperationalError:
        print(f"\nUse only AND, OR NOT and parentheses in the search string.\n")
        exit(1)


    if len(search_result) > 0:

        print_rows(search_result)

    else:

        click.echo(f"\nNone found.\n")
        

@dose.command()
@click.argument('medication')
@click.argument('start_time', required=False, type=click.DateTime())
@click.argument('end_time', required=False, type=click.DateTime())
def count(medication, start_time, end_time):

    '''Some stats regarding doses between two dates.  Defaults to last 30 days.'''

    if start_time == None:

        start_time = datetime.datetime.now() - datetime.timedelta(days=30)

    if end_time == None:

        end_time = datetime.datetime.now()
    
    seconds = (end_time - start_time).total_seconds()
    
    days = seconds/24/60/60

    if days <= 0:
        
        click.echo("\nStart time is later than end time.\n")

        exit(1)

    sql = '''select count(*) as count from dose where name = ? and datetime between ? and ?'''
    
    doses = db.execute(sql, (medication, start_time, end_time)).fetchone()["count"]

    if doses == 0:

        click.echo(f'\nMedication {medication} not found.\n')
        exit(1)
    
    dosespd = doses/days
    
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

    '''Print all doses between two dates.  Defaults to last 52 weeks.'''

    if start_time is None:

        start_time = datetime.datetime.now() - datetime.timedelta(weeks=52)

    if end_time is None:

        end_time = datetime.datetime.now()
    
    sql = '''select date(datetime) as date, time(datetime) as time, id, name, comment from dose
             where datetime between ? and ? order by datetime'''

    search_result = db.execute(sql, (start_time, end_time)).fetchall()

    if len(search_result) > 0:

        print_rows(search_result)

    else:
        
        click.echo("None found.")



@dose.command()
# @click.option("--comment", "-c", nargs=1, default='')
@click.option('--add', '-a', is_flag=True)
def medications(add):

    '''List medications or add one.
    
       This will prompt for the medication name and comment.'''

    if not add:

        meds = db.execute("select * from medication")

        print("")
        
        print(tabulate.tabulate(meds, tablefmt='plain'))

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

                db.execute(sql, (medication, comment ))

                click.echo(f'Added {medication} to medication table')

        except sqlite3.IntegrityError as e:

            click.echo(f'\nMedication already exists.\n')

            exit(1)

        except sqlite3.Error as e:

            click.echo(f'\nFailed to add medication: {e}\n')

            exit(1)        

if __name__ == '__main__':
    dose()
#    dose(obj={})
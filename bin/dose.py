#!/usr/bin/python

import click
import sqlite3
from pathlib import Path
import datetime as dt
import tabulate
from prompt_toolkit import prompt
#import configparser as cp

try:

    programdir = Path(__file__).parent.resolve()
    
    if 'projects' in str(programdir):

        dbfile = Path().home() / 'projects' / '.local' / 'share' / 'medical.db'
    
    else:

        dbfile = Path().home() / '.local' / 'share' / 'medical.db'

    db = sqlite3.connect(str(dbfile))

    # print(dbfile)

except sqlite3.OperationalError as e:

    click.echo(f'{str(e).capitalize()}: {dbfile}')

    exit(1)


db.execute("pragma foreign_keys = on")

db.row_factory = sqlite3.Row

def list_rows(rows):

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

    #click.echo(tabulate.tabulate(rows_to_print, tablefmt="plain"))
    print(tabulate.tabulate(rows_to_print, tablefmt="plain"))

@click.group()
#@click.pass_context
def dose():
    
    '''Maintain a medication dose database. All date time formats are %Y-%m-%d' or '%Y-%m-%d %H:%M.'''

@dose.command()
@click.argument('name')
@click.argument('datetime', required=False, type=click.DateTime(['%Y-%m-%d','%Y-%m-%d %H:%M']), metavar='[DATE_TIME]')
@click.option('--comment', "-c")
#@click.argument('comment', required=False)
def insert(name, datetime, comment):

    '''Insert a dose with 'NAME' and san optional comment.  If no date-time is given now will be used.'''

    if datetime == None:

        datetime = dt.datetime.now()
    
    if comment == None:

        comment = ''

    sql = '''insert into dose (name, datetime, comment) values( ?, ?, ?)'''

    try:

        with db:

            cursor = db.cursor()

            cursor.execute(sql,(name, datetime, comment))

            click.echo(f"Insertion of dose {cursor.lastrowid} succeeded.")

    except sqlite3.Error as e:

        if 'FOREIGN' in e.args[0]:

            click.echo(f"Medication '{name}' does not exist.")

        else:

            click.echo(f'Dose insertion {e}')
        
        exit(1)


@dose.command()
@click.argument('id', type=int)
def update(id):

    '''Update the dose with the given ID.'''

    sql = '''select name, strftime('%Y-%m-%d %H:%M',datetime), comment from dose where id = ?'''

    dose = db.execute(sql, (id,)).fetchone()
    
    if not dose:

        print(f"Dose {id} not found.")

        exit(1)
        
    ( name, datetime, comment ) = dose
    
    click.echo(f"Updating dose {id}:")

    name = prompt("Name: ", default=name)

    datetime = prompt("Date Time: ", default=datetime)

    comment = prompt("Comment: ", default=comment)
    
    sql = "update dose set name = ?, datetime = datetime(?), comment = ? where id = ?"

    try:

        with db:

            db.execute(sql, (name, datetime, comment, id))
                
    except sqlite3.Error as e:

        click.echo(f'Update dose: {e}')
    
        exit(1)

    click.echo(f'Update of dose {id} succeeded.')
       

@dose.command()
@click.argument('id', type=int)
def delete(id):

    '''Delete the dose with the given ID'''

    sql = 'delete from dose where id = ?'

    try:

        with db:

            deleted = db.execute(sql,(id,))

            db.commit

            if deleted.rowcount == 0:

                click.echo(f"Deletion of dose {id} failed.")

                exit(1)

            else:

                click.echo(f'Deletion of dose {id} succeeded.')               

    except sqlite3.Error as e:

        click.echo(e)

        exit(1)


@dose.command()
@click.argument('search_string')
@click.argument('start_time', required=False, type=click.DateTime(['%Y-%m-%d','%Y-%m-%d %H:%M']), metavar='[START_TIME]')
@click.argument('end_time', required=False  , type=click.DateTime(['%Y-%m-%d','%Y-%m-%d %H:%M']), metavar='[END_TIME]')
#@click.pass_context
def search(search_string, start_time, end_time):

    """Case insensitive search of dose names and comments between two date-times.  
    The search string may contain the operators *, (), AND, OR and NOT.  Start time defaults to
    1 year ago. End time defaults to now.    
    """

    if start_time is None:

        start_time = dt.datetime.now() - dt.timedelta(weeks=52)

    if end_time is None:

        end_time = dt.datetime.now()
    
    sql = '''select date(datetime) as date, strftime('%H:%M', datetime) as time, id, name, comment from dose 
            where id in ( select docid from doseft where doseft match ? ) 
            and datetime between ? and ? order by datetime'''

    try:

        search_result = db.execute(sql, (search_string, start_time, end_time)).fetchall()
    
    except sqlite3.OperationalError:

        print(f"Use only AND, OR, NOT, * and () in the search string.")

        exit(1)

    if len(search_result) > 0:

        list_rows(search_result)

    else:

        click.echo(f"None found.")
        

@dose.command()
@click.argument('name')
@click.argument('start_time', required=False, type=click.DateTime(['%Y-%m-%d','%Y-%m-%d %H:%M']), metavar='[START_TIME]')
@click.argument('end_time', required=False, type=click.DateTime(['%Y-%m-%d','%Y-%m-%d %H:%M']), metavar='[END_TIME]')
def count(name, start_time, end_time):

    '''Print statistics regarding doses between two dates.  Defaults to last 30 days.'''

    if start_time == None:

        start_time = dt.datetime.now() - dt.timedelta(days=30)

    if end_time == None:

        end_time = dt.datetime.now()
    
    seconds = (end_time - start_time).total_seconds()
    
    days = seconds/24/60/60

    if days <= 0:
        
        click.echo("Start time is later than end time.")

        exit(1)

    sql = '''select count(*) as count from dose where name = ? and datetime between ? and ?'''
    
    doses = db.execute(sql, (name, start_time, end_time)).fetchone()["count"]

    if doses == 0:

        click.echo(f"Dose named '{name}' not found.")

        exit(1)
    
    dosespd = doses/days
    
    click.echo(f'      Name: {name}')
    click.echo(f'      From: {start_time.isoformat(sep=" " , timespec="minutes")}')
    click.echo(f'        To: {end_time.isoformat(sep= " ", timespec="minutes")}')
    click.echo(f'     Doses: {doses}')
    click.echo(f'      Days: {days:.2f}')
    click.echo(f' Doses/Day: {dosespd:.2f}')
    

@dose.command()
@click.argument('start_time', required=False, type=click.DateTime(['%Y-%m-%d','%Y-%m-%d %H:%M']), metavar='[START_TIME]')
@click.argument('end_time', required=False  , type=click.DateTime(['%Y-%m-%d','%Y-%m-%d %H:%M']), metavar='[END_TIME]')
def list(start_time, end_time):

    '''List all doses between two dates.  Defaults to last 52 weeks.'''

    if start_time is None:

        start_time = dt.datetime.now() - dt.timedelta(weeks=52)

    if end_time is None:

        end_time = dt.datetime.now()
    
    sql = '''select date(datetime) as date, strftime('%H:%M', datetime) as time, id, name, comment from dose
             where datetime between ? and ? order by datetime'''

    search_result = db.execute(sql, (start_time, end_time)).fetchall()

    if len(search_result) > 0:

        list_rows(search_result)

    else:
        
        click.echo("None found.")


if __name__ == '__main__':
    dose()
#    dose(obj={})

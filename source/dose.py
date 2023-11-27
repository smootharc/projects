#!/usr/bin/python

import click
import sqlite3
from pathlib import Path
import datetime as dt
import tabulate
from prompt_toolkit import prompt
from prompt_toolkit.validation import Validator, ValidationError
import re
#import configparser as cp

def dbopen(readonly=False):

    try:

        programdir = Path(__file__).parent.resolve()
        
        if 'projects' in str(programdir):

            dbfile = Path().home() / 'projects' / '.local' / 'share' / 'medical.db'
        
        else:

            dbfile = Path().home() / '.local' / 'share' / 'medical.db'

        uri = 'file:' + str(dbfile)

        if readonly:

            db = sqlite3.connect(uri + '?mode=ro', uri=True)

        else:

            db = sqlite3.connect(uri, uri=True)

        db.execute("pragma foreign_keys = on")

        db.row_factory = sqlite3.Row

    except sqlite3.OperationalError as e:

        click.echo(f'{str(e).capitalize()}: {dbfile}')

        exit(1)


    return db

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

    click.echo(tabulate.tabulate(rows_to_print, tablefmt="plain"))

@click.group()
def dose():
    
    '''Maintain a medication dose database.
    
    All time formats are %H:%M, %Y-%m-%d or %Y-%m-%d %H:%M.
    '''

@dose.command()
@click.argument('name')
@click.argument('datetime', required=False, type=click.DateTime(['%H:%M','%Y-%m-%d %H:%M']), metavar='[TIME]')
@click.option('--comment', "-c")
def insert(name, datetime, comment):

    '''Insert a dose with NAME.
    
    An optional comment and a TIME in the format %H:%M or %Y-%m-%d %H:%M.  If the given TIME is absent or in the future the current time will be used.
    '''
    
    if comment == None:

        comment = ''
    
    if datetime == None:

        datetime = dt.datetime.now()
        
    if datetime.year == 1900:

        now = dt.datetime.now()

        datetime = datetime.replace(year=now.year, month=now.month, day=now.day)

    if datetime > dt.datetime.now():

        datetime = dt.datetime.now()

        click.echo("Future times are not supported.  Inserting using the current time.")

    sql = '''insert into dose (name, datetime, comment) values( ?, ?, ?)'''

    db = dbopen()

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

class UpdateDateValidator(Validator):

    def validate(self, document):

        text = document.text
        
        isValidDate = True

        try:

            dt.datetime.strptime(text, '%Y-%m-%d %H:%M')

        except ValueError:

            isValidDate = False
        
        if not re.match(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}', text):

            isValidDate = False

        if not isValidDate:

            raise ValidationError(message = 'Time must be of the form: %Y-%m-%d %H:%M')

@dose.command()
@click.argument('id', type=int)
def update(id):

    '''Update the dose having the given ID.
    '''

    db = dbopen()

    sql = '''select name, strftime('%Y-%m-%d %H:%M',datetime), comment from dose where id = ?'''

    dose = db.execute(sql, (id,)).fetchone()
    
    if not dose:

        click.echo(f"Dose {id} not found.")

        exit(1)
        
    ( name, datetime, comment ) = dose
    
    click.echo(f"Updating dose {id}:")

    name = prompt("Name: ", default=name)

    datetime = prompt("Date Time: ", default=datetime, validator=UpdateDateValidator(), validate_while_typing=False)

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

    '''Delete the dose having the given ID.  The ID must be an integer.
    '''

    db = dbopen()

    sql = 'delete from dose where id = ?'

    try:

        with db:

            deleted = db.execute(sql,(id,))

            if deleted.rowcount == 0:

                click.echo(f"Deletion of dose {id} failed. Are you sure it exists?")

                exit(1)

            else:

                confirmation = click.prompt('Type the dose ID again to confirm deletion', type=int)
                
                if confirmation != id:

                    click.echo(f'Confirmation failed. Dose {id} not deleted.' )

                    db.rollback()

                else:

                    click.echo(f'Deletion of dose {id} succeeded.')

    except sqlite3.Error as e:

        click.echo(e)

        exit(1)


@dose.command()
@click.argument('search_string')
@click.argument('start_time', required=False, type=click.DateTime(['%Y-%m-%d','%Y-%m-%d %H:%M']), metavar='[START_TIME]')
@click.argument('end_time', required=False  , type=click.DateTime(['%Y-%m-%d','%Y-%m-%d %H:%M']), metavar='[END_TIME]')
def search(search_string, start_time, end_time):

    """Case insensitive search of dose names and comments between START_TIME and END_TIME.

    SEARCH_STRING may contain the operators *, (), AND, OR and NOT.  Valid time formats are %Y-%m-%d or %Y-%m-%d %H:%M.  Start time defaults to 1 year ago.
    End time defaults to the current time.
    """

    db = dbopen(True)

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

        click.echo('Search error: Use only the operators *, (), AND, OR and NOT in the search string.  Valid time formats are %Y-%m-%d or %Y-%m-%d %H:%M.')

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

    '''Print statistics regarding doses for NAME between two times.
    
    Valid time formats are %Y-%m-%d or %Y-%m-%d %H:%M. If no dates are given, the last 30 days are searched.
    '''

    db = dbopen(True)

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

    '''List all doses between START_TIME and END_TIME.
    
    Valid time formats are %Y-%m-%d or %Y-%m-%d %H:%M.  If no times are given the last 30 days will be listed.
    '''

    db = dbopen(True)

    if start_time is None:

        start_time = dt.datetime.now() - dt.timedelta(days=30)

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

#!/usr/bin/python

# vi:syntax=python

import sqlite3
import click
from tabulate import tabulate
from pathlib import Path
import datetime as dt
from prompt_toolkit import prompt
from prompt_toolkit.validation import Validator, ValidationError
import re

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

@click.group()
def weight():

    '''Maintain a weight and food database.
    '''


@weight.command()
@click.argument('search', required=False, type=click.STRING(None))
@click.option('--begin_date', '-b', type=click.DateTime(['%Y-%m-%d']), metavar='[BEGIN_DATE]')
@click.option('--end_date', '-e', type=click.DateTime(['%Y-%m-%d']), metavar='[END_DATE]')
def select(search, begin_date, end_date):

    """Print records from the weight table.  Optionally limit what records are printed by including only records that satisfy the search
    criteria specified in the SEARCH parameter and have dates falling between the BEGIN_DATE and END_DATE.
    
    The SEARCH parameter may be blank or contain the operators *, (), AND, OR and NOT.  Valid date format is %Y-%m-%d.  START_DATE defaults to 365 days ago.
    END_DATE defaults to the current date.
    """

    db = dbopen(True)

    if begin_date is None and end_date is not None:

        begin_date = end_date - dt.timedelta(days=365)

    if begin_date is None and end_date is None:

        end_date = dt.datetime.now()
        begin_date = end_date - dt.timedelta(days=365)

    if end_date is None:

        end_date = dt.datetime.now() #+ dt.timedelta(days=1)

    #include begin and end dates.  Don't know why the begin date is not included unless I subtract one from it.

    begin_date = begin_date - dt.timedelta(days=1)

#    end_date = end_date + dt.timedelta(days=1)
    
    if search is None:

        sql = '''select id, date(date) as date, weight, food from weight 
                where date >= ? and date <= ? order by date'''

        parameters = (begin_date, end_date)

    elif search == "":
    
        sql = '''select id, date(date) as date, weight, food from weight 
                where food = "" and date >= ? and date <= ? order by date'''

        parameters = (begin_date, end_date)

    else:

        sql = '''select id, date(date) as date, weight, food from weight 
                where id in ( select docid from weightft where weightft match ? )
                and date >= ? and date <= ? order by date'''

        parameters = (search, begin_date, end_date)

    try:

        table = db.execute(sql, parameters).fetchall()

        if len(table) > 0:

            table = db.execute(sql, parameters)

        else:

            click.echo(f"None found.")

            exit(0)
    
    except sqlite3.OperationalError:

        click.echo('Search error: Use only an empty string or the operators *, (), AND, OR and NOT in the search parameter.  The valid date format is %Y-%m-%d.')

        exit(1)

    names = [description[0].upper() for description in table.description]

    print(tabulate(table,names))

#    print(sql,parameters)

@weight.command()
@click.option('--date', '-d', type=click.DateTime(['%Y-%m-%d']), default=str(dt.date.today()))
@click.option('--weight', '-w', type=click.FLOAT, default=0)
@click.option('--food', '-f', default='')
def insert(date, weight, food):

    '''Insert a record into the weight database.
    '''

    date = date.strftime('%Y-%m-%d')

    sql = '''insert into weight (date, weight, food) values(?, ?, ?)'''

    db = dbopen()

    try:

        with db:

            cursor = db.cursor()

            cursor.execute(sql, (date, weight, food))

            click.echo(f"Insertion of weight {cursor.lastrowid} succeeded.")

    except sqlite3.Error as e:

        if 'FOREIGN' in e.args[0]:

            click.echo(f"Medication '{name}' does not exist.")

        else:

            click.echo(f'Weight insertion {e}')
        
        exit(1)

class UpdateDateValidator(Validator):

    def validate(self, document):

        text = document.text
        
        isValidDate = True

        try:

            dt.datetime.strptime(text, '%Y-%m-%d')

        except ValueError:

            isValidDate = False
        
        if not re.match(r'\d{4}-\d{2}-\d{2}', text):

            isValidDate = False

        if not isValidDate:

            raise ValidationError(message = 'Time must be of the form: %Y-%m-%d')

class UpdateFloatValidator(Validator):

    def validate(self, document):

        text = document.text

        try:

            float(text)

        except ValueError:

            raise ValidationError(message = 'Must be a floating point number')

@weight.command()
@click.argument('id', type=int)
def update(id):

    '''Update the weight record having the given ID.
    '''

    db = dbopen()

    sql = '''select strftime('%Y-%m-%d',date), weight, food from weight where id = ?'''

    weight = db.execute(sql, (id,)).fetchone()
    
    if not weight:

        click.echo(f"Weight {id} not found.")

        exit(1)
        
    ( date, weight, food ) = weight

    if food == None:

        food = ''

    sql = "update dose set name = ?, datetime = datetime(?), comment = ? where id = ?"
    
    click.echo(f"Updating weight record: {id}")

    date = prompt("Date: ", default=date, validator=UpdateDateValidator(), validate_while_typing=False)

    weight = prompt("Weight: ", default=str(weight), validator=UpdateFloatValidator(), validate_while_typing=False)

    food = prompt("Food: ", default=food)
    
    sql = "update weight set date = date(?), weight = ?, food = ? where id = ?"

    try:

        with db:

            db.execute(sql, (date, weight, food, id))
                
    except sqlite3.Error as e:

        click.echo(f'Update weight: {e}')
    
        exit(1)

    click.echo(f'Update of weight {id} succeeded.')


@weight.command()
@click.argument('id', type=int)
def delete(id):

    '''Delete the weight record having the given ID.  The ID must be an integer.
    '''

    db = dbopen()

    sql = 'delete from weight where id = ?'

    try:

        with db:

            deleted = db.execute(sql,(id,))

            if deleted.rowcount == 0:

                click.echo(f"Deletion of weight {id} failed. Are you sure it exists?")

                exit(1)

            else:

                if click.confirm(f'Confirm deletion of weight record with ID number: {id}', default=False, show_default=True):
                
                    click.echo(f'Deletion of weight {id} succeeded.')

                else:

                    click.echo(f'Confirmation failed. weight {id} not deleted.' )

                    db.rollback()

    except sqlite3.Error as e:

        click.echo(e)

        exit(1)

if __name__ == '__main__':
        weight()

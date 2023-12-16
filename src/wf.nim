import std/os
import std/parseopt
import std/strutils
import db_connector/db_sqlite
import std/times
import std/options
import noise
# import std/re
# import std/terminal
# import std/rdstdin
# import std/sequtils

let appName = extractFileName(getAppFileName())

const subCommands = ["select", "insert", "update", "delete"]

proc help(subcommand: string, exitCode: int = QuitSuccess, ) =

  case subcommand

    of "select":

      echo "Usage: " & appName & " select [OPTIONS] [SEARCH]\n"

      echo """
  Print records from the weight table.  Optionally limit what records are printed by including only records that satisfy the search
  criteria specified in the SEARCH parameter and have dates falling between the BEGIN_DATE and END_DATE.

  The SEARCH parameter may be blank or contain the operators *, (), AND, OR and NOT.  Valid date format is yyyy-MM-dd.  BEGIN_DATE defaults to 52 weeks ago.
  END_DATE defaults to the current date.

  Options:
    -b, [BEGIN_DATE]
    -e, [END_DATE]
    -h, Show this message and exit.
  """

    of "insert":

      echo "Usage: " & appName & " insert [DATE] [WEIGHT] [FOOD]\n"
      echo """
  Insert records into the weight table. All arguments are optional.
  The defaults are DATE = today, WEIGHT = zero and [FOOD] = "". 

  Options:
    -h Show this message and exit.
  """

    of "update":

      echo "Usage: " & appName & " update [OPTIONS] ID.\n"
      echo """
  Update the weight record having the given ID. The ID must be an integer greater than or equal to zero.

  Options:
    -h  Show this message and exit.
  """

    of "delete":

      echo "Usage: " & appName & " delete [OPTIONS] ID\n"
      echo """
  Delete the weight record having the given ID.  The ID must be an integer greater than or equal to zero.

  Options:
    -h Show this message and exit.
  """

    of "main":

      echo "Usage: " & appName & " [OPTIONS] COMMAND [ARGS]...\n"
      echo """
  Maintain a weight and food database.

  Options:
    -h  Show this message and exit.

  Commands:
    select  Print records from the weight table.
    insert  Insert a record into the weight table.
    update  Update a weight record having a given ID.
    delete  Delete a weight record having a given ID.

    For help on any command follow the command with -h.
  """

  quit(exitCode)

proc opendb(readonly: bool = false): DbConn =

  var 
    appdir: string = getAppDir()
    dbpath: string

  if "projects" in appdir:

    dbpath = parentDir(appdir) / ".local/share/medical.db" 

  else:

    dbpath = getHomeDir() / ".local/share/medical.db"
    
  let db = open(dbpath, "", "", "")

  if readonly:

    db.exec(sql"PRAGMA query_only = true")

  result = db
    
proc select(beginstr, endstr, searchstr: Option[string]) =

  var
    endtime: DateTime = now() + initDuration(days = 1)
    begintime: DateTime = endtime - initDuration(weeks = 52)
    sqlstring: SqlQuery

  if beginstr.isSome():

    try:

      begintime = parse(beginstr.get, "yyyy-MM-dd")

    except TimeParseError as e:

      quit(appName & ": " & e.msg)
      
  if endstr.isSome():

    try:

      endtime = parse(endstr.get, "yyyy-MM-dd")

    except TimeParseError as e:

      quit(appName & ": " & e.msg)

  if endtime < begintime:

    quit("End Date must be later the begin date.", QuitFailure)

  var db = opendb(readonly = true)

  var rows: seq[Row]

  if searchstr.isNone():

    sqlstring = sql"select id, date(date) as date, weight, food from weight where date >= ? and date <= ? order by date"

    rows = db.getAllRows(sqlstring, begintime.format("yyyy-MM-dd"), endtime.format("yyyy-MM-dd"))

  elif searchstr.get == "":
  
    sqlstring = sql"select id, date(date) as date, weight, food from weight where food = '' and date >= ? and date <= ? order by date"

    rows = db.getAllRows(sqlstring, begintime.format("yyyy-MM-dd"), endtime.format("yyyy-MM-dd"))
  
  elif searchstr.isSome():

    try:    

      var searchstring = searchstr.get

      if searchstring.startsWith("NOT "):

        searchstring.removePrefix("NOT ")

        sqlstring = sql"""select id, date(date) as date, weight, food from weight
                where id not in ( select docid from weightft where weightft match ? )
                and date >= ? and date <= ? order by date"""
      else:

        sqlstring = sql"""select id, date(date) as date, weight, food from weight
                where id in ( select docid from weightft where weightft match ? )
                and date >= ? and date <= ? order by date"""

      rows = db.getAllRows(sqlstring, searchstring, begintime.format("yyyy-MM-dd"), endtime.format("yyyy-MM-dd"))

    except DbError as e:

     if "fts5" in e.msg:
        
       quit(appName & " select: Encountered a search error. Use only the operators *, (), AND, OR and NOT in the search parameter.  The valid date format is yyyy-MM-dd.")
      
  for row in rows:

    echo alignleft(row[0],6), alignleft(row[1], 11),  align(row[2], 7), "  ", row[3]
  
proc insert(date: Option[DateTime], weight: Option[float], food: string = "") =

  var
    datestr: string
    weightstr: string
    id: string

  if date.isSome:

    datestr = date.get.format("yyyy-MM-dd")

  else:

    datestr = now().format("yyyy-MM-dd")

  if weight.isSome:

    weightstr = weight.get.formatFloat(ffDecimal, 1)

  else:

    weightstr = "0"

  var db = opendb()

  var sql = sql"insert into weight (date, weight, food) values(?, ?, ?)"

  try:

    db.exec(sql, datestr, weightstr, food)

  except DbError as e:

    if e.msg.contains("UNIQUE"):

      quit(appName & ": There is already an entry for that date: " & datestr)
  
  finally:

    sql = sql"select last_insert_rowid()"

    id = db.getValue(sql)

    echo "Successfully inserted a row with the id " & id    

    db.close()

proc update(id: Natural) =

  var sql = sql"select date, weight, food from weight where id = ?"

  let db = opendb()

  var row: Row

  try:

    row = db.getRow(sql,id) 

    doAssert row != @["", "", ""]

  except AssertionDefect:

    echo appName, " update: No record with that ID was found. Are you sure it exists?" 

  var noise = Noise.init()

  noise.setPrompt("Date: ")

  var date = row[0]

  noise.preloadBuffer(date)

  if noise.readLine():

    date = noise.getLine()

    try:
    
      date = date.parse("yyyy-MM-dd").format("yyyy-MM-dd")

    except TimeParseError as e:

      quit(appName & " update: " & e.msg)

  noise.setPrompt("Weight: ")

  var weight = row[1]

  noise.preloadBuffer(weight)

  if noise.readLine():

    weight = noise.getLine()

    try:

      let f = parseFloat(weight)

      doAssert f < 300 and f >= 0

    except ValueError, AssertionDefect:

      quit(appName &  " update: The weight must be a floating point number less then 300 and greater then or equal to 0.  The decimal point is optional.")
   
  noise.setPrompt("Food: ")

  var food = row[2]

  noise.preloadBuffer(food)

  if noise.readLine():

    food = noise.getLine()

  sql = sql"update weight set date = date(?), weight = ?, food = ? where id = ?"

  if db.tryExec(sql, date, weight, food, id):

    echo "Update of the weight record with ID: ", id, " succeeded."

  else:

    quit("Update of the weight record with ID: " & $id & " failed.")

proc delete(id: int) =

  let db = opendb()

  try:
  
    discard db.getValue(sql"select id from weight where id = ?", id).parseInt()

  except ValueError:

    quit("The weight table does not have a record with the ID: " & $id & ".")

  db.exec(sql"BEGIN")

  if db.tryExec(sql"delete from weight where id = ?", id):

    stdout.write("Confirm the deletion of the weight record with the ID: " & $id & " by pressing y. ")
    
    var answer = getch()

    if answer == 'y':

      db.exec(sql"COMMIT")

      echo "\nDeleted the record with the ID: ", id, "."

    else:

      db.exec(sql"ROLLBACK")

      echo "\nDid not delete the record with the ID: ", id, "."

  db.close()

proc main() =

  var parameters = commandLineParams()

  if paramCount() == 0:

    help("main", QuitFailure)

  if paramCount() == 1 and "-h" == parameters[0]:

    help("main", QuitSuccess)

  if paramCount() > 1 and parameters[0] notin subCommands:

      help("main", QuitFailure)

  case parameters[0]

    of "select":

      if paramCount() > 1 and parameters[1] == "-h":

        help("select")

      var subCommandParameters: array[3, Option[string]]

      var p = initOptParser()

      subCommandParameters[2] = none(string)

      while true:

        p.next()

        case p.kind

          of cmdEnd: break

          of cmdLongOption:

            quit(appName & ": " & "'--" & p.key & "' Long options are not supported.")

          of cmdShortOption:

            case p.key

              of "b":

                  subCommandParameters[0] = some(p.val)

              of "e":

                  subCommandParameters[1] = some(p.val)

          of cmdArgument:

            if p.key != "select":

              subCommandParameters[2] = some(p.key)

      select(subCommandParameters[0], subCommandParameters[1], subCommandParameters[2])

    of "insert":

      var
        date: Option[DateTime]
        weight: Option[float]
        food: string

      var p = initOptParser()

      while true:

        p.next

        case p.kind

          of cmdEnd: break

          of cmdLongOption:

              quit(appName & ": " & "'--" & p.key & "' Long options are not supported.")

          of cmdShortOption:

            case p.key

              of "h":

                help("insert")

              of "d":

                try:

                  date = some(p.val.parse("yyyy-MM-dd"))

                except ValueError:

                  quit("Invalid date. Dates must be in yyyy-MM-dd format.")

              of "w":

                try:

                  weight = some(p.val.parseFloat())

                except ValueError:

                  quit("Invalid weight. Weights must be floating point numbers.")

          of cmdArgument:

            if p.key != "insert":

              food.add(" " & p.key)

      food = food.strip()  

      insert(date, weight, food)

    of "update":

      let p = commandLineParams()

      var id : Natural

      if paramCount() > 2:

        help("update", QuitFailure)

      if paramCount() == 2 and p[1] == "-h":

        help("update")

      try:

        id = parseInt(p[1])

      except:

        help("update", QuitFailure)

      update(id)

    of "delete":

      let p = commandLineParams()

      var id: Natural

      if paramCount() > 2:

        help("delete", QuitFailure)

      if paramCount() == 2 and p[1] == "-h":

        help("delete")

      try:

        id = parseInt(p[1])

      except:

        help("delete", QuitFailure)

      delete(id)

main()

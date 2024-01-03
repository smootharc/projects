import std/os
import std/parseopt
import std/strutils
import db_connector/db_sqlite
import std/times
import std/options
import noise

let appName = extractFileName(getAppFileName())

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

  else:

    db.exec(sql"pragma foreign_keys = on")
    
  result = db

proc help(subcommand: string, exitCode: int = QuitSuccess, ) =

  case subcommand

    of "select":

      echo "Usage: " & appName & " select [OPTIONS] [SEARCH]\n"

      echo """
  Print records from the dose table.  Optionally limit what records are printed by including only records that satisfy the search
  criteria specified in the SEARCH parameter and have dates falling between the BEGIN_TIME and END_TIME.

  The SEARCH parameter may be blank or contain the operators *, (), AND, OR and NOT.  The valid time format is "yyyy-MM-dd HH:mm".
  If BEGIN_TIME is not given it defaults to 52 weeks ago.  If END_TIME is not given it defauts to the current time.

  Options:
    -b[=|:]BEGIN_TIME
    -e[=|:]END_TIME
    -h, Show this message and exit.

  Single letter options that take a parameter require an equal sign or a colon between the option and the argument.
  """

    of "insert":

      echo "Usage: " & appName & " insert [OPTIONS...] MEDICATION_NAME\n"

      echo """
  Insert a record into the dose table. The MEDICATION_NAME must be provided.
  The default for the options are TIME = now and COMMENT = "". The TIME 
  option if provided, must be either 'yyyy-MM-dd HH:mm' or 'HH:mm'.

  Options:
    -t[=|:]TIME.
    -c[=|:]COMMENT.
    -h Show this message and exit.

  Single letter options that take a parameter require an equal sign or a colon between the option and the argument.
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

    of "count":
      echo "Usage: " & appName & " count [OPTIONS] NAME [START_TIME] [END_TIME]\n"
      echo """
  Print statistics regarding doses for NAME between two times.

  Valid time formats are yyyy-MM-dd or yyyy-MM-dd HH:m. If no dates are given,
  the last 30 days are counted.

  Options:
    --h Show this message and exit.
  """

    of "main":

      echo "Usage: " & appName & " [OPTIONS] COMMAND [ARGS]...\n"
      echo """
  Maintain a medications dose database.

  Options:
    -h  Show this message and exit.

  Commands:
    select  Print records from the weight table.
    insert  Insert a record into the weight table.
    update  Update a weight record having a given ID.
    delete  Delete a weight record having a given ID.
    count   Print statistics about a medication.

    For help on any command follow the command with -h.
  """

  quit(exitCode)

proc select(beginstr, endstr, searchstr: Option[string]) =

  var
    endtime: DateTime = now() + initDuration(days = 1)
    begintime: DateTime = endtime - initDuration(days= 30)
    sqlstring: SqlQuery

  if beginstr.isSome():

    try:

      begintime = parse(beginstr.get, "yyyy-MM-dd HH:mm")

    except TimeParseError as e:

      # quit(appName & " select: " & e.msg)
      quit("$1 select: $2" % [appName, e.msg])
      
  if endstr.isSome():

    try:

      endtime = parse(endstr.get, "yyyy-MM-dd HH:mm")

    except TimeParseError as e:

      quit("$1 select: $2" % [appName, e.msg])

  if endtime < begintime:

    # quit(appName & " select: The END_TIME must be later the BEGIN_TIME.", QuitFailure)
    quit("$1 select: The END_TIME must be later than the BEGIN_TIME." % appName)

    # help("select")

  var db = opendb(readonly = true)

  var rows: seq[Row]

  if searchstr.isNone():
  
    sqlstring = sql"select date(datetime) as date, strftime('%H:%M', datetime) as time, id, name, comment from dose where date >= ? and date <= ? order by datetime"

    rows = db.getAllRows(sqlstring, begintime.format("yyyy-MM-dd HH:mm"), endtime.format("yyyy-MM-dd HH:mm"))

  # elif searchstr.get == "":
  
  #   sqlstring = sql"select id, date(date) as date, weight, food from weight where food = '' and date >= ? and date <= ? order by date"

  #   rows = db.getAllRows(sqlstring, begintime.format("yyyy-MM-dd"), endtime.format("yyyy-MM-dd"))
  
  elif searchstr.isSome():

    if beginstr.isNone():

      begintime = endtime - initDuration(weeks= 52)

    try:    

      var searchstring = searchstr.get

      if searchstring.startsWith("NOT "):

        searchstring.removePrefix("NOT ")

        sqlstring = sql"""select date(datetime) as date, strftime('%H:%M', datetime) as time, id, name, comment from dose
                where id not in ( select docid from doseft where doseft match ? )
                and date >= ? and date <= ? order by datetime"""
      else:

        sqlstring = sql"""select date(datetime) as date, strftime('%H:%M', datetime) as time, id, name, comment from dose
                where id in ( select docid from doseft where doseft match ? )
                and date >= ? and date <= ? order by datetime"""
        # sqlstring = sql"""select id, date(date) as date, weight, food from weight
        #         where id in ( select docid from weightft where weightft match ? )
        #         and date >= ? and date <= ? order by date"""

      rows = db.getAllRows(sqlstring, searchstring, begintime.format("yyyy-MM-dd"), endtime.format("yyyy-MM-dd"))

    except DbError as e:

     if "fts5" in e.msg:
        
       quit("$1 select: Encountered a search error. Use only the operators *, (), AND, OR and NOT in the search parameter.  The valid date format is yyyy-MM-dd." % appName)

  if rows.len == 0:

    echo appName, " select: No records found containg: ", searchstr.get
      
  var lastdate = ""

  var date = ""
  
  for row in rows:

    if lastdate == row[0]:

      date = ""

    else:

      lastdate = row[0]

      date = row[0]

      echo ""
    
    echo alignleft(date,10), align(row[1], 7),  align(row[2], 7), "  ", row[3], "\t", row[4]

proc insert(name: string, datetime: var string, comment: string = "") =

  try:

    if datetime == "":

      datetime = now().format("yyyy-MM-dd HH:mm")

    elif datetime.len == 5:

      datetime = now().format("yyyy-MM-dd ") & datetime

    elif datetime.len == 16:
  
      datetime = datetime.format("yyyy-MM-dd HH:mm")

    else:

      quit("$1 insert: Invalid time format $2.  Type dose insert -h for help." % [appName, datetime])
          
  except TimeFormatParseError as e:

        quit(appName & " insert: " & e.msg)
      
  if datetime.parse("yyyy-MM-dd HH:mm") > now():

    quit(appName & " insert: " & "TIME can't be in the future.")
  
  var db = opendb()

  var sql = sql"insert into dose (name, datetime, comment) values(?, ?, ?)"

  try:
  
    let id = db.tryInsert(sql, "id", name, datetime, comment)

    if id >= 0:

      echo "Successfully inserted a row with the id " & $id    

    else:

      db.dbError()

  except:

    if "FOREIGN" in getCurrentExceptionMsg():

      db.close()

      # let msg = appName &  " insert: " & "'" & name & "'" & " is not a valid medication."

      quit("$1 insert: $2 is not a valid medication." % [appName, name])

    else:

      echo getCurrentExceptionMsg()

  db.close()

proc update(id: Natural) =

  var sql = sql"select name, strftime('%Y-%m-%d %H:%M',datetime), comment from dose where id = ?"

  let db = opendb()

  var row: Row

  try:

    row = db.getRow(sql,id) 

    doAssert row != @["", "", ""]

  except AssertionDefect:

    quit("$1 update: No record with the ID '$2' was found. Are you sure it exists?" % [appName, $id])

  var noise = Noise.init()

  noise.setPrompt("Name: ")

  var name = row[0]

  noise.preloadBuffer(name)

  if noise.readLine():

    name = noise.getLine()

  noise.setPrompt("Time: ")

  var datetime = row[1]

  noise.preloadBuffer(datetime)

  if noise.readLine():

    datetime = noise.getLine()

    try:
    
      datetime = datetime.parse("yyyy-MM-dd HH:mm").format("yyyy-MM-dd HH:mm")

    except TimeParseError as e:

      quit("$1 update: $2." % [appName, e.msg])
   
  noise.setPrompt("Comment: ")

  var comment = row[2]

  noise.preloadBuffer(comment)

  if noise.readLine():

    comment = noise.getLine()

  sql = sql"update dose set datetime = datetime(?), name = ?, comment = ? where id = ?"

  if db.tryExec(sql, datetime, name, comment, id):

    echo "Update of the dose record with ID: ", id, " succeeded."

  else:

    quit("Update of the dose record with the ID: $2 failed." % [$id])

proc delete(id: int) =

  let db = opendb()

  try:
  
    discard db.getValue(sql"select id from dose where id = ?", id).parseInt()

  except ValueError:

    quit("$1 delete: The dose table does not have a record with the ID: $2." % [appName, $id])

  db.exec(sql"BEGIN")

  if db.tryExec(sql"delete from dose where id = ?", id):

    stdout.write("Confirm the deletion of the weight record with the ID: " & $id & " by pressing y. ")
    
    var answer = getch()

    if answer == 'y':

      db.exec(sql"COMMIT")

      echo "\n", appName, " delete: Deleted the record with the ID: ", id, "."

    else:

      db.exec(sql"ROLLBACK")

      echo "\n", appName, "Did not delete the record with the ID: ", id, "."

  db.close()

proc count(name: string, starttime, endtime: Option[string]) =

  var
    endtimed: DateTime
    starttimed: DateTime

  if starttime.isSome: 

    if starttime.get.len == 10:

      try:

          starttimed = parse(starttime.get, "yyyy-MM-dd")

      except TimeParseError as e:

        quit("$1 count: $2." % [appName, e.msg])

    elif starttime.get.len == 16:

      try:

          starttimed = parse(starttime.get, "yyyy-MM-dd HH:mm")

      except TimeParseError as e:

        quit("$1 count: $2." % [appName, e.msg])

    else:

      quit("$1 count: Invalid time format $2.  Type dose count -h for help." % [appName, starttime.get] )

  if endtime.isSome: 

    if endtime.get.len == 10:

      try:

          endtimed = parse(endtime.get, "yyyy-MM-dd")

      except TimeParseError as e:

        quit("$1 count: $2." % [appName, e.msg])

    elif endtime.get.len == 16:

      try:

          endtimed = parse(endtime.get, "yyyy-MM-dd HH:mm")

      except TimeParseError as e:

        quit("$1 count: $2." % [appName, e.msg])

    else:

      quit("$1 count: Invalid time format $2.  Type dose count -h for help." % [appName, endtime.get] )

  if endtime.isNone:

    endtimed = now()

  if starttime.isNone:

    starttimed = endtimed - initDuration(days = 30) 
    
  let sql = sql"""select count(id) as count from dose where name = ? and datetime between ? and ?"""

  let db = opendb(true)

  let count = db.getValue(sql, name, starttimed.format("yyyy-MM-dd HH:mm"), endtimed.format("yyyy-MM-dd HH:mm"))

  if count == "0":

      quit(appName & " count: No such medication taken during that time period.")

  let days = formatFloat(inSeconds(endtimed - starttimed) /  86400, ffDecimal, precision = 2)

  let dosesperday = formatFloat(count.parseFloat() / days.parseFloat(), ffDecimal, precision = 2)

  echo "     Name: ", name
  echo "     From: ", starttimed.format("yyyy-MM-dd HH:mm")
  echo "       To: ", endtimed.format("yyyy-MM-dd HH:mm")
  echo "    Doses: ", count
  echo "     Days: ", days
  echo "Doses/Day: ", dosesperday

proc main() =

  const subCommands = ["select", "insert", "update", "delete", "count"]

  # echo commandLineParams(), " ", paramCount(), " ", paramStr(1)

  if paramCount() == 0:

    help("main", QuitFailure)

  if paramCount() >= 1 and paramStr(1) notin subCommands:

    help("main", QuitFailure)

  if paramCount() == 1 and "-h" == paramStr(1):

    help("main", QuitSuccess)

  case paramStr(1)

    of "select":

      if paramCount() > 1 and paramStr(2) == "-h":

        help("select")

      var
        beginstr: Option[string]
        endstr: Option[string]
        searchstr: Option[string]

      var p = initOptParser()

      while true:

        p.next()

        case p.kind

          of cmdEnd: break

          of cmdLongOption:

            quit("$1 select: The option '--$2' is not supported.  Try dose select -h for more help." % [appName, p.key])

          of cmdShortOption:

            case p.key

              of "b":

                  beginstr = some(p.val)

              of "e":

                  endstr = some(p.val)

              else:

                quit("$1 select: Valid options are -h, -b and -e. The -h option must be the first.  Try dose select -h for more help." % appName)

          of cmdArgument:

            if p.key != "select":

              searchstr = some(p.key)

      select(beginstr, endstr, searchstr)

    of "insert":

      var
        namestr: string
        datetimestr: string
        commentstr: string

      if paramCount() == 2 and "-h" == paramStr(2):

        help("insert", QuitSuccess)

      var p = initOptParser()

      while true:

        p.next

        case p.kind

          of cmdEnd: break

          of cmdLongOption:

            quit("$1 insert: The option '--$2' is not supported.  Try dose select -h for more help." % [appName, p.key])

          of cmdShortOption:

            case p.key

              of "t":

                if datetimestr.len == 0:
                  datetimestr = p.val

              of "c":

                if commentstr.len == 0:
                  commentstr = p.val

              else:

                quit("$1 insert: Valid insert options are -t and -c.")

          of cmdArgument:

            if p.key != "insert":

              namestr.add(" " & p.key)

      namestr= namestr.strip()  

      insert(namestr, datetimestr, commentstr)

    of "update":

      # let p = commandLineParams()

      var id : Natural

      if paramCount() > 2:

        quit("$1 update: The only parameter needed is the ID of the record your want to update." % appName)

      if paramCount() == 2 and paramStr(2) == "-h":

        help("update")

      try:

        id = parseInt(paramStr(2))

      except:

        quit("$1 update: Requires the integer ID of the record you want to update" % appName)

      update(id)

    of "delete":

      var id: Natural

      if paramCount() > 2:

        quit("$1 delete: Requires the integer ID of the record you want to delete" % appName)

      if paramCount() == 2 and paramStr(2) == "-h":

        help("delete")

      try:

        id = parseInt(paramStr(2))

      except:

        help("delete", QuitFailure)

      delete(id)

    of "count":

      case paramCount()

       of 2:

          if paramStr(2) == "-h":

            help("count")

          else:

            let name = paramStr(1)

            count(name, none(string), none(string))
          
       of 3:

          let name = paramStr(2)

          let starttime = some(paramStr(3))

          count(name, starttime, none(string))

       of 4:

          let name = paramStr(2)

          let starttime = some(paramStr(3))

          let endtime = some(paramStr(4))

          count(name, starttime, endtime)

       else:

        help("count", QuitFailure)

main()

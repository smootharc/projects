import std/os
import std/strutils
import std/times
# import std/math

let appName = extractFileName(getAppFileName())

proc help(error: int = QuitFailure) =

  echo "Usage: $1 [Options] dosesPrescribed dosesPerDay dosesTaken\n" % [appName]

  echo "This program calculates the estimated date and time of the last dose of a prescription medication.\n" 

  echo "All three arguments are required and must be integers.\n"

  echo "Options:"
  echo " -h Show this help message and exit."

  quit(error)

  
if paramStr(1) == "-h":

  help(QuitSuccess)

var
  dosesPrescribed: Natural
  dosesPerDay: Natural
  dosesTaken: Natural

proc durationLeft(dosesPrescribed, dosesPerDay, dosesTaken: Natural): Duration =

  var dosesLeft = dosesPrescribed - dosesTaken

  var secondsLeft = toInt((dosesLeft / dosesPerDay) * 86400)

  result = initDuration(seconds = secondsLeft)
  
try:

  dosesPrescribed = paramStr(1).parseInt()
  dosesPerDay = paramStr(2).parseInt()
  dosesTaken = paramStr(3).parseInt()

except:

  help()

if dosesPrescribed < dosesPerDay or dosesPrescribed < dosesTaken:

  quit("$1: Doses prescribed must be greater than the other parameters." % [appName])

# elif dosesPerDay > dosesTaken:

#   quit("$1: Doses per day must be less than the other parameters." % [appName])

var secondsLeft = durationLeft(dosesPrescribed, dosesPerDay, dosesTaken)

echo "Time left until the last dose: ", secondsLeft #.inSeconds()

echo "Date and time of last dose is: ", (now() + secondsLeft).format("dddd, d MMMM yyyy HH:mm")

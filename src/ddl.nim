import std/os
import std/times
from std/strutils import parseInt, `%`
export strutils

const downloads = expandTilde("~/Downloads")

proc isEmptyDir(path: string): bool =

  var count: int

  result = false

  for f in walkDir(path):

    count += 1

  if count == 0:

    result = true

proc rmEmptyDir(dir: string) =

  for d in walkDirRec(dir, {pcDir}):

    if isEmptyDir(d):

      removeDir(d)

    for p in parentDirs(d):

      if isEmptyDir(p) and p != downloads:

        removeDir(p)

proc ddl*(minutes: Natural) =

  for f in walkDirRec(downloads, {pcFile}):

    if getFileSize(f) == 0:

      removeFile(f)

    if fileExists(f):

      var age = getTime() - getCreationTime(f)

      if age.inMinutes >= minutes:

        removeFile(f)

  rmEmptyDir(downloads)

when isMainModule:

  let appName = extractFileName(getAppFileName())

  var minutes: Natural = high(Natural)
  
  if paramCount() == 1:

    try:

      minutes = paramStr(1).parseInt()

    except:

      quit("Usage: $1 [M]\n\nAll files in the ~/Downloads directory older than M minutes will be deleted.  Empty directories will be deleted.\nM must be an integer greater than or equal to zero.\n" % appName)

  ddl(minutes)

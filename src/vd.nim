import std/os
import std/parseopt
import std/mimetypes
import std/times
import std/tempfiles
import std/algorithm
import std/strutils # Why import this if std/os imports it?
import std/re
import ddl
# import std/parsecfg
#import std/sequtils
#import std/dirs
#import std/files
#import magic

when defined(release):

  let release = true

else:

  let release = false

type file = tuple
  name: string
  time: Time

var
  images: seq[file]
  videos: seq[file]
  m = newMimetypes()
  appdir = getAppDir()
  parentdir = parentDir(getAppDir())
  deletecontaining: seq[string]

proc isOnPath(): bool =

    let path = split(getEnv("PATH"),":")

    appdir in path

proc help(errorlevel: int = QuitSuccess) =
  echo "Usage: ", extractFileName(getAppFileName()), " [OPTION]... [DIRECTORY] [default: ~/Downloads]\n"
  echo """
  Display images and videos contained in a DIRECTORY where each absolute pathname contains some regex.
  If no regex is given display all.  By default sorted newest to oldest. 
  """
  # echo ""
  echo """
  The options are:
  
  -f[=:]TEXT           Display only files containing the regex TEXT in the absolute pathname of the file.
                       If any of TEXT contain capital letters the search will be case sensitive.
  -m[=:]INTEGER        Delete files in the ~/Downloads folder older than INTEGER minutes.
  -s[=:][n,o,a,r]      Sort by time, newest first or time, oldest first. Name alphabetically or name alphabetically reversed. [default: n, newest first]
  -h                   Show this message and exit.
  
  An equal sign or a colon separates the option from the option value.
  """
  quit(errorlevel)

proc openConfig() =

  try:

    if release and isOnPath():

      deletecontaining = readFile(getHomeDir() / ".config/vd/vd.cfg").split("\n")

    else:

      deletecontaining = readFile(parentdir / ".config/vd/vd.cfg").split("\n")

  except IOerror:

    discard

# proc processFile(filename: string, substring: string = ".*") =
proc processFile(filename: string, substring: string = ".*") =

  var file: file

  var searchfor: Regex
    
  if substring.contains({'A'..'Z'}):

    searchfor = re(substring)

  else:

    searchfor = re(substring, {reIgnoreCase})

  if "_unpack" notin filename:

    for s in deletecontaining:

      if expandTilde("~/Downloads") in filename and s in filename and s.len > 0:

        filename.removeFile()

    if filename.contains(searchfor):
      
      var ext = splitFile(filename).ext
  
      var mimetype = m.getMimetype(ext)

      file.name = filename

      try:

        file.time = filename.getCreationTime()

      except OSError:

        discard
    
      if "image" in mimetype:

        images.add(file)

      elif "video" in mimetype:

        videos.add(file)

      elif expandTilde("~/Downloads") in filename:

        filename.removeFile()
       
var
  sort: string = "n"
  minutes: Natural = high(Natural)
  substr: string
  args: seq[string] #= commandLineParams()
  p = initOptParser()
  
if "-h" in args:
  help()
  
while true:
  p.next()
  case p.kind
  of cmdEnd: break
  of cmdLongOption:
    quit("Long options are not supported.")
  of cmdShortOption:
    case p.key
    of "s":
      if p.val notin ["n", "o", "a", "r"]:
        quit("Invalid value for -s option. Valid options are n, o, a and r. [Default = n]")
      case p.val
      of "n","o","a","r":
        sort = p.val
      else:
        echo "Valid options for option -s are n, o, a and r."
    of "m":
      try:
        minutes = parseint(p.val)
      except:
        quit("Option -m requires an integer argument greater than or equal to zero.")
    of "f":
      if p.val == "":
        quit("Option -f requires an argument.")
      else:
        substr = p.val

    of "h":
      help()
    else:

      quit("Invalid option -" & $p.key & ".")

  of cmdArgument:

    args.add(p.key)

if args.len == 0:

  args.add(expandTilde("~/Downloads"))

openConfig()
    
for a in args:

  if a.fileExists():

    processFile(a, substr)

  elif a.dirExists():

    for f in walkDirRec(a):

      processFile(f, substr)

proc sorttimeasc(x, y: file): int =
  cmp(x.time, y.time)

proc sorttimedes(x, y: file): int =
  cmp(y.time, x.time)

proc sortnameasc(x, y: file ): int =
  cmp(x.name.toLowerAscii(), y.name.toLowerAscii())
  
proc sortnamedes(x, y: file ): int =
  cmp(y.name.toLowerAscii(), x.name.toLowerAscii())

case sort
  of "n":
    images.sort(sorttimedes)
    videos.sort(sorttimedes)
  of "o":
    images.sort(sorttimeasc)
    videos.sort(sorttimeasc)
  of "a":
    images.sort(sortnameasc)
    videos.sort(sortnameasc)
  of "r":
    images.sort(sortnamedes)
    videos.sort(sortnamedes)
  else:

    discard
if images.len > 0:
  let (tfile, path) = createTempFile("images", ".tmp")
  defer: path.removeFile()
  for f in images:
    tfile.write f.name, "\n"
  tfile.setFilePos 0
  discard execShellCmd("feh -dqFf " & path & "&> /dev/null")
  # path.removeFile()
else:
  echo "No images found!"
  
if videos.len > 0:
  let (tfile, path) = createTempFile("videos", ".tmp")
  defer: path.removeFile()
  for f in videos:
    tfile.write f.name, "\n"
  tfile.setFilePos 0
  discard execShellCmd("mpv --really-quiet --playlist=" & path)
  # path.removeFile()
else:
  echo "No videos found!"

ddl(minutes)

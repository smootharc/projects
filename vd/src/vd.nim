import std/os
import strutils
import std/parseopt
import std/mimetypes
import std/times
import std/tempfiles
import std/algorithm
import std/re
import ddl #ddl exports strutils
#import magic

type File = tuple
  name: string
  time: Time

var
  images: seq[File]
  videos: seq[File]

let m = newMimetypes()

let deletenot = re(".*par2|.*zip|.*rar|.*r[[:digit]]{2}")

template processFile(filename: string, substring: string = ".*") =

  var 
    file: File
    searchfor: Regex
    
  if substring.contains({'A'..'Z'}):
    searchfor = re(substring)
  else:
    searchfor = re(substring, {reIgnoreCase})

  if "_unpack" notin filename:
    if filename.contains(searchfor):
      let ext = splitFile(filename).ext
      let mimetype = m.getMimetype(ext)
      file.name = filename
      try:
        file.time = filename.getCreationTime()
      except OSError:
        discard
      if "image" in mimetype:
        images.add(file)
      elif "video" in mimetype:
        videos.add(file)
      # elif expandTilde("~/Downloads") in filename and not filename.extractFileName.endsWith(".zip") and not filename.extractFileName.endsWith(".rar"):
      elif expandTilde("~/Downloads") in filename and not filename.endsWith(deletenot):
        filename.removeFile()

proc help(errorlevel: int = QuitSuccess) =
  echo "Usage: ", extractFileName(getAppFileName()), " [OPTION]... [DIRECTORY]... [default: ~/Downloads] [FILE]...\n"
  echo """
  Display images and videos contained in DIRECTORYs and FILEs where each absolute pathname contains some regex.
  If no regex is given display all.  Options and arguments may appear in any order. 
  """
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
       
var
  sort: string = "n"
  minutes: Natural = high(Natural)
  substr: string
  args: seq[string]
  p = initOptParser()

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
    args.add(p.key.absolutePath)

if args.len == 0:
  args.add(expandTilde("~/Downloads"))

for a in args:
  if a.fileExists():
    processFile(a, substr)
  elif a.dirExists():
    for f in walkDirRec(a):
      processFile(f, substr)

proc sorttimeasc(x, y: File): int =
  cmp(x.time, y.time)

proc sorttimedes(x, y: File): int =
  cmp(y.time, x.time)

proc sortnameasc(x, y: File ): int =
  cmp(x.name.toLowerAscii(), y.name.toLowerAscii())
  
proc sortnamedes(x, y: File ): int =
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
else:
  echo "No images found!"
  
if videos.len > 0:
  let (tfile, path) = createTempFile("videos", ".tmp")
  defer: path.removeFile()
  for f in videos:
    tfile.write f.name, "\n"
  tfile.setFilePos 0
  discard execShellCmd("mpv --really-quiet --playlist=" & path)
else:
  echo "No videos found!"

ddl(minutes)

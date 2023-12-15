import std/os
import std/strutils  # Why import this if std/os imports it?
import std/parseopt
import std/mimetypes
import std/times
import std/tempfiles
import std/algorithm
import std/re

#import std/sequtils
#import std/dirs
#import std/files
#import magic

type file = tuple
  name: string
  time: Time

var
  images: seq[file]
  videos: seq[file]

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
  -s[=:][n,o,a,ar]     Sort by time, newest first or time, oldest first. Name alphabetically or name alphabetically reversed. [default: n, newest first]
  -h                   Show this message and exit.
  
  An equal sign or a colon separates the option from the option value.
  """
  quit(errorlevel)

proc getimagesandvideos(dir: string, substring: string = ".*") = #: (seq[file], seq[file]) =
 
  var m = newMimetypes()
  
  var searchfor: Regex

  var file: file

  for f in walkDirRec(dir):
    
      if "_unpack" in f:
        continue
        
      if substring.contains({'A'..'Z'}):
        searchfor = re(substring)
      else:
        searchfor = re(substring, {reIgnoreCase})

      if not f.contains(searchfor):
        continue
          
      var ext = splitFile(f).ext
      
#      echo ext
      
      var mimetype = m.getMimetype(ext)

      file.name = f
      try:
        file.time = f.getCreationTime()
      except OSError:
        continue
      # file.time = getLastAccessTime(f)
      # file.time = getFileInfo(f).lastWriteTime

      if "image" in mimetype:
        images.add(file)
      elif "video" in mimetype:
        videos.add(file)
            
  # result = (images, videos)
 
proc main() =

  var
    dir: string = expandTilde("~/Downloads")
    sort: string = "t"
    minutes: Natural = high(Natural)
    substr: string
    # imagesandvideos: (seq[file], seq[file])
    args: seq[string] = commandLineParams()
    p = initOptParser(args)
    
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
        if p.val notin ["o", "n", "a", "ar"]:
          quit("Invalid value for -s option. Valid options are n, o, a and ar.")
        case p.val
        of "n":
          sort = "n"
        of "tr":
          sort = "o"
        of "a":
          sort = "a"
        of "ar":
          sort = "ar"
        else:
          echo "Valid options for option -s are td, ta, nd and na."
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
      else:
        #let msg = "Invalid option -"& $p.key
        quit("Invalid option -" & $p.key & ".")
    of cmdArgument:
      dir = p.key.absolutePath()
      
  if dirExists(dir):
    # imagesandvideos = getimagesandvideos(dir, substr)
    getimagesandvideos(dir, substr)
  else:
    quit(extractFileName(getAppFilename()) & ": The directory " & dir & " does does not exist!")

  proc sorttimeasc(x, y: file): int =
    cmp(x.time, y.time)

  proc sorttimedes(x, y: file): int =
    cmp(y.time, x.time)
  
  proc sortnameasc(x, y: file ): int =
    cmp(x.name.toLowerAscii(), y.name.toLowerAscii())
    
  proc sortnamedes(x, y: file ): int =
    cmp(y.name.toLowerAscii(), x.name.toLowerAscii())
  
  case sort
    of "t":
      images.sort(sorttimedes)
      videos.sort(sorttimedes)
    of "tr":
      images.sort(sorttimeasc)
      videos.sort(sorttimeasc)
    of "a":
      images.sort(sortnameasc)
      videos.sort(sortnameasc)
    of "ar":
      images.sort(sortnamedes)
      videos.sort(sortnamedes)
    else:
      discard
#[
  images = imagesandvideos[0]
  for f in images:
    echo f

  videos = imagesandvideos[1]
  for f in videos:
    echo f
  
  quit()
]#

  if images.len > 0:
    let (tfile, path) = createTempFile("images", ".tmp")
    defer: path.removeFile()
    for f in images:
      tfile.write f.name, "\n"
    tfile.setFilePos 0
    discard execShellCmd("feh -dqFf " & path)
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
  
  if dir == expandTilde("~/Downloads"):
    discard execShellCmd("ddl " & $minutes)

main()

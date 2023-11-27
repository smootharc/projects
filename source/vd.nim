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

type files = tuple
  time: Time
  name: string

var
  images: seq[files]
  videos: seq[files]

proc help(errorlevel: int = 0) =
  echo "Usage: ", extractFileName(getAppFileName()), " [OPTION]... [DIRECTORY]\n"
  echo """
  Display images and videos contained in a DIRECTORY where each absolute pathname contains some substring.
  If no substring is given display all.  By default sorted newest to oldest."""
  echo ""
  echo """
  The options are:
  
  -f[=:]TEXT           Display only files containing the regex TEXT in the absolute pathname of the file.
                       If any of TEXT contain capital letters the search will be case sensitive.
  -m[=:]INTEGER        Delete files in the ~/Downloads folder older than INTEGER minutes.
  -s[=:][t,tr,a,ar]    Sort by time, newest first or time oldest first. Name alphabetical or name alphabetical reversed. [default: t, newest first.]
  -h                   Show this message and exit.
  
  An equal sign or a colon separates the option from the option value.
  """
  quit(errorlevel)

proc getimagesandvideos(dir: string, substring: string = ".*"): (seq[files], seq[files]) =
 
  var m = newMimetypes()
  
  var searchfor: Regex
            
  for file in walkDirRec(dir):
    
      if "_unpack" in file:
        continue
        
      if substring.contains({'A'..'Z'}):
        searchfor = re(substring)
      else:
        searchfor = re(substring, {reIgnoreCase})

      if not file.contains(searchfor):
        continue
          
      var ext = splitFile(file).ext
      
#      echo ext
      
      var mimetype = m.getMimetype(ext)
          
      if "image" in mimetype:
        images.add((getLastAccessTime(file),file))
      elif "video" in mimetype:
        videos.add((getLastAccessTime(file),file))
            
  result = (images, videos)
 
proc main() =

  var
    dir: string = expandTilde("~/Downloads")
    sort: string = "t"
    minutes: Natural = high(Natural)
    substr: string
    imagesandvideos: (seq[files],seq[files])
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
        if p.val notin ["t", "tr", "a", "ar"]:
          quit("Invalid value for -s option. Valid options are t, tr, a and ar.")
        case p.val
        of "t":
          sort = "t"
        of "tr":
          sort = "tr"
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
    imagesandvideos = getimagesandvideos(dir, substr)
  else:
    quit(extractFileName(getAppFilename()) & ": The directory " & dir & " does does not exist!")

  images = imagesandvideos[0]
      
  videos = imagesandvideos[1]
  
  proc sortnameasc(x, y: files ): int =
    cmp(x.name.toLowerAscii(), y.name.toLowerAscii())
    
  proc sortnamedes(x, y: files ): int =
    cmp(y.name.toLowerAscii(), x.name.toLowerAscii())
  
  case sort
    of "t":
      images = images.sorted(Descending)
      videos = videos.sorted(Descending)
    of "tr":
      images = images.sorted(Ascending)
      videos = videos.sorted(Ascending)
    of "a":
      images.sort(sortnameasc)
      videos.sort(sortnameasc)
    of "ar":
      images.sort(sortnamedes)
      videos.sort(sortnamedes)
    else:
      discard
   
  if images.len > 0:
    let (tfile, path) = createTempFile("images", ".tmp")
    for f in images:
      tfile.write f.name, "\n"
    tfile.setFilePos 0
    discard execShellCmd("feh -dqFf " & path)
    path.removeFile()
  else:
    echo "No images found!"
    
  if videos.len > 0:
    let (tfile, path) = createTempFile("videos", ".tmp")
    for f in videos:
      tfile.write f.name, "\n"
    tfile.setFilePos 0
    discard execShellCmd("mpv --really-quiet --playlist=" & path)
    path.removeFile()
  else:
    echo "No videos found!"
  
  if dir == expandTilde("~/Downloads"):
    discard execShellCmd("ddl " & $minutes)
      
main()

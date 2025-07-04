# Package

version       = "1.0"
author        = "Paul A. Medeiros"
description   = "View images and videos."
license       = "MIT"
srcDir        = "src"
paths         = @["../ddl"] 
bin           = @["vd"]

# Dependencies

requires "nim >= 2.2.4"

task deploy, "Install vd to ~/.local/bin":
  exec "nim c -d:release --app:console --opt:speed --outdir:$HOME/.local/bin src/vd.nim"
  

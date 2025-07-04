# Package

version       = "1.0"
author        = "Paul A. Medeiros"
description   = "Delete old files in ~/Downloads."
license       = "MIT"
srcDir        = "src"
bin           = @["ddl"]


# Dependencies

requires "nim >= 2.2.4"

task deploy, "Install ddl to ~/.local/bin":
  exec "nim c -d:release --app:console --opt:speed --outdir:$HOME/.local/bin src/ddl.nim"

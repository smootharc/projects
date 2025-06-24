# Package

version       = "1.0"
author        = "Paul A. Medeiros"
description   = "Weight and food logging program."
license       = "MIT"
srcDir        = "src"
bin           = @["wf"]


# Dependencies

requires "nim >= 2.2.4"
requires "db_connector"
requires "noise"

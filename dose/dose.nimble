# Package

version       = "1.0"
author        = "Paul A. Medeiros"
description   = "Log medications taken."
license       = "MIT"
srcDir        = "src"
bin           = @["dose"]


# Dependencies

requires "nim >= 2.2.4"
requires "db_connector >= 0.1.0"
requires "noise"

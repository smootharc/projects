all: ~/.local/bin/dose ~/.local/bin/vd ~/.local/bin/synchome ~/.local/bin/ddl ~/.local/bin/weight ~/.local/bin/exdl

gcalcli: ~/.local/bin/dosenow ~/.local/bin/medical ~/.local/bin/medical.sql

~/.local/bin/dose: bin/dose
	cp bin/dose ~/.local/bin/dose

~/.local/bin/vd: bin/vd
	cp bin/vd ~/.local/bin/vd

~/.local/bin/synchome: bin/synchome
	cp bin/synchome ~/.local/bin/synchome

~/.local/bin/ddl: bin/ddl
	cp bin/ddl ~/.local/bin/ddl

~/.local/bin/weight: bin/weight
	cp bin/weight ~/.local/bin/weight

~/.local/bin/exdl: bin/exdl
	cp bin/exdl ~/.local/bin/exdl

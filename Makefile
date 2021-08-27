all: ~/.local/bin/dose ~/.local/bin/vd ~/.local/bin/synchome ~/.local/bin/ddl ~/.local/bin/wf ~/.local/bin/exdl ~/.local/bin/rss ~/.local/bin/eld

gcalcli: ~/.local/bin/dosenow ~/.local/bin/medical ~/.local/bin/medical.sql

~/.local/bin/dose: bin/dose
	cp bin/dose ~/.local/bin/dose

~/.local/bin/vd: bin/vd
	cp bin/vd ~/.local/bin/vd

~/.local/bin/synchome: bin/synchome
	cp bin/synchome ~/.local/bin/synchome

~/.local/bin/ddl: bin/ddl
	cp bin/ddl ~/.local/bin/ddl

~/.local/bin/wf: bin/wf
	cp bin/wf ~/.local/bin/wf

~/.local/bin/exdl: bin/exdl
	cp bin/exdl ~/.local/bin/exdl

~/.local/bin/rss: bin/rss
	cp bin/rss ~/.local/bin/rss

~/.local/bin/eld: bin/eld.fish
	cp bin/eld.fish ~/.local/bin/eld

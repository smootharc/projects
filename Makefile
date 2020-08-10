all: ~/.local/bin/dose ~/.local/bin/vd ~/.local/bin/synchome ~/.local/bin/ddl ~/.xonshrc ~/.bash_aliases ~/.local/bin/weight ~/.local/bin/exdl

gcalcli: ~/.local/bin/dosenow ~/.local/bin/medical ~/.local/bin/medical.sql

~/.local/bin/dose: bin/dose.py
	cp bin/dose.py ~/.local/bin/dose

~/.local/bin/exdl: bin/exdl
	cp bin/exdl ~/.local/bin/exdl

~/.local/bin/weight: bin/weight
	cp bin/weight ~/.local/bin/weight

~/.local/bin/vd: bin/vd.py
	cp bin/vd.py ~/.local/bin/vd

~/.local/bin/synchome: bin/synchome
	cp bin/synchome ~/.local/bin/synchome

~/.local/bin/ddl: bin/ddl
	cp bin/ddl ~/.local/bin/ddl

~/.xonshrc: .xonshrc
	cp .xonshrc ~/.xonshrc

~/.bash_aliases: .bash_aliases
	cp .bash_aliases ~/.bash_aliases

~/.local/bin/medical: bin/medical
	cp bin/medical ~/.local/bin/medical

~/.local/bin/medical.sql: bin/medical.sql
	cp bin/medical.sql ~/.local/bin/medical.sql

~/.local/bin/dosenow: bin/dosenow
	cp bin/dosenow ~/.local/bin/dosenow

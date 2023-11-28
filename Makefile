#all: ~/.local/bin/dose ~/.local/bin/vd ~/.local/bin/synchome ~/.local/bin/ddl ~/.local/bin/wf ~/.local/bin/eld
all: source/vd.nim
	nim c -o=bin/vd -d=release source/vd.nim
	nim c -o=bin/dose -d=release source/dose.nim
	nim c -o=bin/wf -d=release source/wf.nim


install: source/dose.py source/synchome.sh source/ddl.bash source/wf.py source/eld.fish bin/vd bin/wf bin/dose
	install -vC bin/vd ~/.local/bin/vd
#	install -vC bin/wf ~/.local/bin/wf
#	install -vC bin/dose ~/.local/bin/dose
	install -vC source/dose.py ~/.local/bin/dose
	install -vC source/synchome.sh ~/.local/bin/synchome
	install -vC source/ddl.bash ~/.local/bin/ddl
	install -vC source/wf.py ~/.local/bin/wf
	install -vC source/eld.fish ~/.local/bin/eld

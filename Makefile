all: 

wf:
ifeq ($(release),1)
	nim c -o=bin/wf -d=release src/wf.nim
else
	nim c -o=bin/wf src/wf.nim
endif

vd:
	nim c -o=bin/vd -d=release src/vd.nim

dose:
	nim c -o=bin/dose -d=release src/dose.nim

.PHONY: install
install: 
	install -vC bin/vd ~/.local/bin/vd
#	install -vC bin/wf ~/.local/bin/wf
#	install -vC bin/dose ~/.local/bin/dose
	install -vC src/eld.fish ~/.local/bin/eld
	install -vC src/ddl.bash ~/.local/bin/ddl
	install -vC src/dose.py ~/.local/bin/dose
	install -vC src/synchome.sh ~/.local/bin/synchome
	install -vC src/wf.py ~/.local/bin/wf

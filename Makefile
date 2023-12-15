all: 

wf:
ifeq ($(release),1)
	nim c -o=bin/wf -d=release source/wf.nim
else
	nim c -o=bin/wf source/wf.nim
endif

vd:
	nim c -o=bin/vd -d=release source/vd.nim

dose:
	nim c -o=bin/dose -d=release source/dose.nim

.PHONY: install
install: 
	install -vC bin/vd ~/.local/bin/vd
#	install -vC bin/wf ~/.local/bin/wf
#	install -vC bin/dose ~/.local/bin/dose
	install -vC source/eld.fish ~/.local/bin/eld
	install -vC source/ddl.bash ~/.local/bin/ddl
	install -vC source/dose.py ~/.local/bin/dose
	install -vC source/synchome.sh ~/.local/bin/synchome
	install -vC source/wf.py ~/.local/bin/wf

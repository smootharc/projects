all: 

wf:
ifeq ($(release),1)
	nim c --app=console -o=bin/wf -d=release src/wf.nim
else
	nim c --app=console -o=bin/wf src/wf.nim
endif

eld:
ifeq ($(release),1)
	nim c --app=console -o=bin/eld -d=release src/eld.nim
else
	nim c --app=console -o=bin/eld src/eld.nim
endif

vd:
ifeq ($(release),1)
	nim c --app=console -o=bin/vd -d=release src/vd.nim
else
	nim c --app=console -o=bin/vd src/vd.nim
endif

dose:
ifeq ($(release),1)
	nim c --app=console -o=bin/dose -d=release src/dose.nim
else
	nim c --app=console -o=bin/dose src/dose.nim
endif

ddl:
ifeq ($(release),1)
	nim c --app=console -o=bin/ddl -d=release src/ddl.nim
else
	nim c --app=console -o=bin/ddl src/ddl.nim
endif

.PHONY: install
install: 
	install -vC bin/vd ~/.local/bin/vd
	install -vC bin/wf ~/.local/bin/wf
	# install -vC bin/dose ~/.local/bin/dose
	install -vC bin/eld ~/.local/bin/eld
	# install -vC src/ddl.bash ~/.local/bin/ddl
	install -vC bin/ddl ~/.local/bin/ddl
	# install -vC src/dose.py ~/.local/bin/dose
	install -vC bin/dose ~/.local/bin/dose
	install -vC src/synchome.sh ~/.local/bin/synchome

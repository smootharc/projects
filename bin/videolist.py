#!/usr/bin/env python3
import os
import sys
import time
import mimetypes

if len(sys.argv) < 2:
	print("Usage: videolist.py DirectoryName", file=sys.stderr, end="\n")
	sys.exit(1)

if not os.path.isdir(sys.argv[1]):
	print(sys.argv[0], ": ", sys.argv[1], " is not directory.", file=sys.stderr, sep="", end="\n")
	sys.exit(2)

def getVideoExtensions():
	allextensions = []
	mimetypes = open("/etc/mime.types")
	for line in mimetypes.readlines():
		if line.startswith("video"):
			lasttab = line.rfind("\t")
			if lasttab > 0:
	#			print(lasttab, line, sep=" ", end = "\n") 
				extensions = line[lasttab + 1:-1 ]
				extensions = extensions.split()
	#			print(extensions)
				for ext in extensions:
					allextensions.append(ext)
					#print(allextensions)
	mimetypes.close()
	return(allextensions)

def fileHasVideoExtension(filename, videoextensions):
	f, e = os.path.splitext(filename)
	e = e.replace(".","")
	e = e.lower()
#	print(e, end = "\n")
#	time.sleep(.1)
	if e in videoextensions:
		return(True)
	else:
		return(False)

def getFileList(directory):
	filelist = []
	for root, dirs, files in os.walk(directory):
		for name in files:
			name = os.path.abspath(os.path.join(root, name))
			filelist.append(name)
#			filelist.append(os.path.join(root, name))
			
#		for name in dirs:
			#filelist.append(os.path.join(root, name))
		
	return(filelist)

videoextensions = getVideoExtensions()
filelist = getFileList(sys.argv[1])
videolist = []
for f in filelist:
	if fileHasVideoExtension(f, videoextensions): 
		videolist.append(f)
#time.sleep(.1)	

playlist = open("/tmp/playlist.txt","w")

for line in videolist:
	playlist.write("%s\n" % line)

sys.exit(0)	

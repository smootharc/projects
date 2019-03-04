#!/bin/python

import os
import sys
import stat
import mimetypes
import tempfile
import argparse

parser = argparse.ArgumentParser(description="View images and videos in ~/Downloads.")
parser.add_argument("-m", type=int, help="Delete files older than M minutes.")
args = parser.parse_args()

minutes = str(args.m)
#print(minutes)

path = os.path.expanduser("~/Downloads")
    
images = []

videos = []

other = []

folders = []

mimetypes.init

for root,d_names,f_names in os.walk(path):
    for name in f_names:
        fullname = os.path.join(root,name)
        file_type = mimetypes.guess_type(fullname)
        if file_type[0] is not None:
            if "video" in file_type[0]:
                videos.append((fullname, os.stat(fullname).st_ctime))
            if "image" in file_type[0]:
                images.append((fullname, os.stat(fullname).st_ctime))
        # else:
        #      other.append(fullname)

if len(images) > 0:
    images.sort(key = lambda ctime: ctime[1], reverse = True)
    with tempfile.NamedTemporaryFile(mode='w+', encoding='utf-8') as tf:
    #with tempfile.NamedTemporaryFile() as tf:
        with open(tf.name, "w") as fd:
            for i in images:
                fd.write(i[0] + "\n")
        os.system(f'feh -dqFf {fd.name}')
else:
    print("No images found!")

if len(videos) > 0:
    videos.sort(key = lambda ctime: ctime[1], reverse = True)
    with tempfile.NamedTemporaryFile(mode='w+', encoding='utf-8') as tf:
    #with tempfile.NamedTemporaryFile() as tf:
        with open(tf.name, "w") as fd:
            fd.write("#EXTM3U\n")
            for v in videos:
                fd.write(v[0] + "\n")
        os.system(f'mpv --really-quiet {fd.name}')
else:
    print('No videos found!')

# if len(other) > 0:
#     for f in other:
#         if os.path.isfile(f):
#             os.remove(f)

os.system(f'ddl {minutes}')

#!/bin/python

import os
import sys
import stat
import mimetypes
import tempfile
import argparse

parser = argparse.ArgumentParser(description="View images and videos in Directory.")
parser.add_argument("-m", type=int, nargs='?', default=-1, help="Delete files older than M minutes for M >= 0.")
parser.add_argument("Directory", nargs='?', default=os.path.expanduser("~/Downloads"), help="Directory to view.")
args = parser.parse_args()

path = os.path.abspath(args.Directory)

images = []

videos = []

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

if len(images) > 0:
    images.sort(key = lambda ctime: ctime[1], reverse = True)
    with tempfile.NamedTemporaryFile(mode='w+', encoding='utf-8') as tf:
        with open(tf.name, "w") as fd:
            for i in images:
                try:
                    fd.write(i[0] + "\n")
                except UnicodeError:
                    continue
 
        os.system(f'feh -dqFf {fd.name}')
else:
    print("No images found!")

if len(videos) > 0:
    videos.sort(key = lambda ctime: ctime[1], reverse = True)
    with tempfile.NamedTemporaryFile(mode='w+', encoding='utf-8') as tf:
        with open(tf.name, "w") as fd:
            fd.write("#EXTM3U\n")
            for v in videos:
                try:
                    fd.write(v[0] + "\n")
                except UnicodeError:
                    continue

        os.system(f'mpv {fd.name}')
else:
    print('No videos found!')

if args.m >= 0:
    os.system(f'ddl {args.m}')
#else:
#    os.system(f'ddl')

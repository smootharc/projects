#!/usr/bin/env python

# vi:syntax=python

#import os
import tempfile
import click
import mimetypes
import subprocess
from pathlib import Path

@click.command()

#@click.option('-n', is_flag=True, 'nosort', help='No sort.')
@click.option('-n', 'nosort', is_flag=True, help='No sort.')

@click.option('-m','--minutes', type=int, required=False, help='Delete files older than INTEGER minutes.')

@click.option('-d', '--directory', default=Path('~/Downloads').expanduser(), type=click.Path(exists=True), show_default=True, help='Directory to search.' )

@click.option('-f', '--files', required=False, default='.', show_default=True, help='Return absolute pathnames matching the regex TEXT.')

#@click.option('-d', '--directory', show_default=True )
#@click.argument('directory', required=False, nargs=1, default='~/Downloads')
#@click.argument('files', required=False, nargs=-1)
#@click.option('-f', '--files', metavar='FILES|DIRECTORY', required=False, default='~/Downloads', show_default=True, nargs=-1s)

def main(minutes, files, directory, nosort):

    '''Display images and videos from a directory that have absolutes pathnames matching some regex.  Normally sorted newest to oldest.'''

    files = subprocess.run(['fd', '-E', '_unpack', '-a', '-p', '-t', 'f', files, directory], stdout=subprocess.PIPE, check=True, text=True).stdout.splitlines()        

    #files = [file.strip() for file in !(fd -E _unpack -a -p -t f @(files) @(Path(directory).expanduser()) )]
        
    videos = []

    images = []

    mimetypes.init


    for file in files:
        
        try:

            mime_type = mimetypes.guess_type(file)[0]

            if mime_type is not None:

                if 'video' in mime_type:

                    videos.append((file, Path(file).stat().st_ctime))

                if 'image' in mime_type:
                
                    images.append((file, Path(file).stat().st_ctime))

        except FileNotFoundError as e:

            click.echo(e)


    if len(images) > 0:
        if not nosort:
            images.sort(key = lambda fctime: fctime[1], reverse = True)
        with tempfile.NamedTemporaryFile(mode='w+', encoding='utf-8') as tf:
            with open(tf.name, "w") as fd:
                for i in images:
                    try:
                        fd.write(i[0] + "\n")
                    except UnicodeError:
                        continue

#            feh -dqFf @(f'{fd.name}')
            subprocess.run(['feh', '-dqFf', fd.name])
    
    else:

        print("No images found!")

    if len(videos) > 0:
        if not nosort:
            videos.sort(key = lambda fctime: fctime[1], reverse = True)
        with tempfile.NamedTemporaryFile(mode='w+', encoding='utf-8') as tf:
            with open(tf.name, "w") as fd:
                fd.write("#EXTM3U\n")
                for v in videos:
                    try:
                        fd.write(v[0] + "\n")
                    except UnicodeError:
                        continue

            #mpv @(f'{fd.name}')
            subprocess.run(['mpv', fd.name])
    
    else:

        print('No videos found!')

    if minutes is None:

        subprocess.run(['ddl'])

#        ddl @(f'{minutes}')

    else:

        subprocess.run(['ddl', str(minutes)])

if __name__ == '__main__':
    main()

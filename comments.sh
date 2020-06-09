#!/bin/sh
FILE="$1"
vorbiscomment "$FILE" > comments.txt
sed 's/^title=\([A-Za-z]\)\(.*\)/title=\U\1\L\2/' -i.bak comments.txt
cp comments.txt comments.src
sed -i -e 's/=/="/' -e 's/$/"/' comments.txt
sed -e 's/=/="/' -e 's/$/"/' -i.bak comments.txt.bak
. ~/comments.txt
[ -z "${disc}" ] && PATHDST="Musique/${artist}/${date} - ${album}/${tracknumber} - ${title}.ogg" || PATHSRC="Musique/${artist}/${date} - ${album}/CD${disc}/${tracknumber} - ${title}.ogg"
. ~/comments.txt.bak
[ -z "${disc}" ] && PATHSRC="Musique/${artist}/${date} - ${album}/${tracknumber} - ${title}.ogg" || PATHDST="Musique/${artist}/${date} - ${album}/CD${disc}/${tracknumber} - ${title}.ogg"
[ "$PATHSRC" != "$PATHDST" ] && echo "mv $PATHSRC $PATHDST"
#vorbiscomment -w -c comments.src "$PATHDST"
rm -f comments*

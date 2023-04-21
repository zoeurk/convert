#!/bin/sh
if test -z "$1"
then
	echo "Usage: $0 repertoire"
	exit
fi
DIR="$(mktemp -d)"
TRACK=`find "$1" -name \*.ogg -print | cat -n | tail -n 1 | sed 's/ *\([0-9]\+\).*/\1/'`
ls -1 "$1" | \
while read E;
do
	test -d "$E" && echo "$E"
done >> "$DIR"/grp.txt
while read GRP
do
	G_TRACK="$(find "$1"/"$GRP" -name \*.ogg -print | cat -n | tail -n 1 | sed 's/ *\([0-9]\+\).*/\1/')"
	POURCENTAGE="$(echo "scale=6;100*$G_TRACK/$TRACK" | bc)"
	test -z ${POURCENTAGE%%.*} && POURCENTAGE=0$POURCENTAGE
	echo "$GRP: $POURCENTAGE%"
done < "$DIR"/grp.txt
rm -r $DIR

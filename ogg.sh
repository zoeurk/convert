#!/bin/sh
DIRECTORY=""
SCRIPT=""
GENRE=""
REWRITE=""
DO=0
DRYRUN=0
#ARTIST=""
#ALBUM=""
#DISC=
#YEAR=
#TRACK=
#TITLE=""
#META="-t COMMENT='' -t COMMENT=''"
while getopts "RPd:g:s:" value
do
 case $value
 in
 R)
  DRYRUN=1
 ;;
 P)
  DO=1
 ;;
 d)
  DIRECTORY="$OPTARG"
 ;;
 g)
  GENRE="$OPTARG"
 ;;
 s)
  SCRIPT="$OPTARG"
 ;;
 *)
  printf "Usage:\n$0 [-P] -d directory -g genre -s script.sed\n"
 ;;
 esac
done
if [ -z "$DIRECTORY" -o -z "$GENRE" -o -z "$SCRIPT" ]
then
 printf "Usage:\n$0 [-P] -d directory -g genre -s script.sed\n"
 exit 0
fi
DIR=`mktemp -d`
find "$DIRECTORY" -regextype sed -regex ".*\.\([mM][pP]3\|flac\|ogg\|m4a\|opus\)" -print >$DIR/files.txt
cp $DIR/files.txt $DIR/files.path
sed -nf $SCRIPT -i $DIR/files.txt
case $DO
in
0)
# grep "ALBUM" $DIR/files.txt | cat -n
 less $DIR/files.txt
 rm -rfv $DIR
 exit
;;
1)
 while [ -s $DIR/files.path ]
 do
  ALBUM=""
  YEAR=""
  DISC=""
  TRACK=""
  TITLE=""
  META=""
  FALSE=0
  INFILE="$(head -n 1 $DIR/files.path)"
  sed -n '1,/^$/ p' $DIR/files.txt >$DIR/src.txt
  . $DIR/src.txt || exit
  if [ $FALSE -eq 1 ]
  then
     sed '1,/^$/ { d; q }' -i $DIR/files.txt
     sed '1 d' -i $DIR/files.path
     continue
  fi
  if [ -z "$ALBUM" -o -z "$YEAR" -o -z "$TRACK" -o -z "$TITLE" ]
  then
  	printf "error: $FALSE::INFILE:$INFILE\nALBUM:$ALBUM\nYEAR:$YEAR\nTRACK:$TRACK\nTITLE:$TITLE\n"
	exit
  fi
  test -d ~/Music_/"$ARTIST" || mkdir ~/Music_/"$ARTIST"
  test -d ~/Music_/"$ARTIST"/"$YEAR - $ALBUM" || mkdir ~/Music_/"$ARTIST"/"$YEAR - $ALBUM"
  if test -n "$DISC"
  then
  	if [ -n "$(printf $DISC | grep -e "^[0-9]*$")" ]
	then
 	 	test ! ~/Music_/"$ARTIST"/"$YEAR - $ALBUM"/CD${DISC} && \
 			mkdir ~/Music_/"$ARTIST"/"$YEAR - $ALBUM"/CD${DISC}
	else
 	 	test ! ~/Music_/"$ARTIST"/"$YEAR - $ALBUM"/"${DISC}" && \
 			mkdir ~/Music_/"$ARTIST"/"$YEAR - $ALBUM"/CD${DISC}
	fi
  fi
  if [ -z "$DISC" ]
  then
   if test ! -e ~/Music_/"$ARTIST/$YEAR - $ALBUM/$TRACK - $TITLE".ogg
   then
   	printf "$INFILE\n" 1>&2
 	test -e "$DIR/track.*" && rm -fv $DIR/track.*
 	cp -v "$INFILE" $DIR/track.${INFILE##*.}
 	printf "Encodage...\n" 1>&2
	test -e $DIR/track.ogg ||\
 	ffmpeg -hide_banner -loglevel quiet \
 		-i $DIR/track.${INFILE##*.} \
 		-ar 48000 -vn -codec:a libvorbis -qscale:a 7 \
 		-y $DIR/track.ogg </dev/null || exit
 	printf \
 		"artist=$ARTIST\nalbum=$ALBUM\ndate=$YEAR\ntracknumber=$TRACK\ntitle=$TITLE\ngenre=$GENRE\n$META\n" \
 			>$DIR/comments.txt
 	sed -e 's/-t /\n/g' -i $DIR/comments.txt
 	sed -e '/^$/d' -i $DIR/comments.txt
 	printf "comments:\n"
	printf "################################\n"
 	cat $DIR/comments.txt
	printf "################################\n"
 	vorbiscomment -w -c $DIR/comments.txt $DIR/track.ogg || exit
 	mv -i -v $DIR/track.ogg \
 		~/Music_/"$ARTIST"/"$YEAR - $ALBUM"/"$TRACK - $TITLE".ogg || exit
   else
   	printf \
 		"Le fichier:Music_/$ARTIST/$YEAR - $ALBUM/$TRACK - $TITLE.ogg exist\n" \
 		| tee -a isdone.txt
   fi
  else
   if [ -n "$(printf "$DISC" | grep -e '^[0-9]*$')" ]
   then
   	test -d ~/Music_/"$ARTIST"/"$YEAR - $ALBUM"/CD${DISC}  || \
   		mkdir ~/Music_/"$ARTIST"/"$YEAR - $ALBUM"/CD${DISC}
   else
   	test -d ~/Music_/"$ARTIST"/"$YEAR - $ALBUM"/"${DISC}"  || \
   		mkdir ~/Music_/"$ARTIST"/"$YEAR - $ALBUM"/"${DISC}"
   fi
   if test ! -e ~/Music_/"$ARTIST/$YEAR - $ALBUM/CD${DISC}/$TRACK - $TITLE".ogg -a ! -e ~/Music_/"$ARTIST/$YEAR - $ALBUM/${DISC}/$TRACK - $TITLE".ogg
   then
   	printf "$INFILE\n" 1>&2
 	cp -v "$INFILE" $DIR/track.${INFILE##*.}
 	printf "Encodage...\n" 1>&2
	test -e $DIR/track.ogg || \
 	ffmpeg -hide_banner -loglevel quiet \
 		-i $DIR/track.${INFILE##*.} \
 		-ar 48000 -vn -codec:a libvorbis -qscale:a 7 \
 		-y $DIR/track.ogg </dev/null || exit
 	printf \
 		"artist=$ARTIST\nalbum=$ALBUM\ndisc=$DISC\ndate=$YEAR\ntracknumber=$TRACK\ntitle=$TITLE\ngenre=$GENRE\n$META\n" \
 			>$DIR/comments.txt
 	sed -e 's/-t /\n/g' -i $DIR/comments.txt
 	sed -e '/^$/d' -i $DIR/comments.txt
 	printf "comments:\n"
	printf "################################\n"
 	cat $DIR/comments.txt
 	printf "################################\n"
	vorbiscomment -w -c $DIR/comments.txt $DIR/track.ogg || exit
 	if [ -n "$(printf "$DISC" | grep -e '^[0-9]*$')" ]
	then
		mv -i -v $DIR/track.ogg \
 			~/Music_/"$ARTIST"/"$YEAR - $ALBUM"/CD${DISC}/"$TRACK - $TITLE".ogg || exit
	else
		mv -i -v $DIR/track.ogg \
			~/Music_/"$ARTIST"/"$YEAR - $ALBUM"/"${DISC}"/"$TRACK - $TITLE".ogg
	fi
   else
  	printf \
 		"Le fichier:Music_/$ARTIST/$YEAR - $ALBUM/CD${DISC}/$TRACK - $TITLE.ogg exist\n" \
 		| tee -a isdone.txt
   fi
  fi
  sed '1,/^$/ { d; q }' -i $DIR/files.txt
  sed '1 d' -i $DIR/files.path
 done
  #find $DIRECTORY -name \*.mp3 -print | cat -n | tail -n 1
  #find Music/$ARTIST -name \*.ogg -print | cat -n | tail -n 1
 
# amixer sset Beep unmute > /dev/null
# for i in $(seq 3)
# do
#  beep;
#  sleep 1
# done
# amixer sset Beep mute >/dev/null
 rm -rfv $DIR
;;
esac

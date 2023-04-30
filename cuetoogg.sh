#!/bin/sh
OUTDIR=~/"Obituary"
ARTIST="$2"
DIR=`mktemp -d`
test -d "$OUTDIR" || mkdir "$OUTDIR"
cat << EOF >> $DIR/bc.script1
h = HEURE
m = MILLISECONDS
s = SCS
x = MINUTES
r = h*60*60*100+x*60*100+s*100+m
print r
quit 
EOF
cat << EOF >>$DIR/bc.script2
h = 0
c = TIME
m = c%100
c = c - m
c = c/100
s = c%60
c = c - s
c = c/60
x = c
if( x > 59) {
	h = x%60
	h = x - h
	h = h/60
	x = x - h*60
	print h
	print ":"
}
print x
print":"
print s
print "."
print m
quit
EOF
encode(){
	case $1
	in
	0)
		echo "ffmpeg -hide_banner -t \"$2\" -i \"$3\" -ar 48000 -vn -codec:a libvorbis -qscale:a 7 -n \"$4\"" >> $DIR/src
	;;
	1)
		echo "ffmpeg -hide_banner -t \"$2\" -ss \"$3\" -i \"$4\" -ar 48000 -vn -codec:a libvorbis -qscale:a 7 -n \"$5\"" >> $DIR/src
	;;
	2)
		echo "ffmpeg -hide_banner -ss \"$2\" -i \"$3\" -ar 48000 -vn -codec:a libvorbis -qscale:a 7 -n \"$4\" " >> $DIR/src
	;;
	esac
}
find "$1" -name \*.cue > $DIR/list.cue
while read LINE;
do
	CUEFILE="$LINE"
	if [ -e "${CUEFILE%*.cue}.flac" ]
	then
		cuebreakpoints "$LINE" >$DIR/breakpoints.txt
		if test ! -s $DIR/breakpoints.txt
		then
			echo "$CUEFILE" >> not_encoded.txt
		       	continue
		fi
		cueprint "$LINE" | sed -n '/^\(track number\|perfomer\|title\):[\t ]/p' >$DIR/songs.txt
		sed 's@/\(.*\)@ (\1)@' -i $DIR/songs.txt
		ALBUM=`head -n 1 $DIR/songs.txt | sed 's/title:[ \t]*//'`
		LEN=0
		MYLEN=0
		_MYLEN_=0
		sed '1d' -i $DIR/songs.txt
		while [ 1 -eq 1 ];
		do
			if [ "$LEN" = "0" ]
			then
				LEN=`head -n 1 $DIR/breakpoints.txt`
				TRACK=`head -n 1 $DIR/songs.txt | sed 's/track number:[\t ]*//'`
				test -z "$2" && ARTIST=`head -n 2 $DIR/songs.txt | tail -n 1 | sed 's/perfomer:[\t ]*//'`
				TITLE=`head -n 3 $DIR/songs.txt | tail -n 1 | sed 's/title:[\t ]*//'`
				YEARS=`echo $CUEFILE | sed 's@^.*/\([0-9]*\( - [0-9]*\)\?\) .*$@\1@'`
				if test -z "$TRACK" -o -z "$ARTIST" -o -z "$TITLE" -o -z "$YEARS" -o -z "$ALBUM"
				then
					printf "Erreur:\nTrack = $TRACK\nArtist = $ARTIST\nAlbum=$ALBUM\nTITLE= $TITLE\nYEAR =$YEARS\nFichier:$CUEFILE\n";
					exit
				fi
				sed '1,3d' -i $DIR/songs.txt
				MIN=${LEN%:*}
				SEC=${LEN#$MIN:}
				SEC=${SEC%.*}
				MIL=${LEN##*.}
				sed -e "s/MINUTES/$MIN/" -e "s/SCS/$SEC/" -e "s/MILLISECONDS/$MIL/" -e 's/HEURE/0/' -i.bak $DIR/bc.script1 || exit
				MYLEN=`bc -q $DIR/bc.script1`
				mv $DIR/bc.script1.bak $DIR/bc.script1
				encode 0 $LEN "${CUEFILE%*.cue}.flac" "$OUTDIR"/"$ARTIST - $YEARS - $ALBUM - $TRACK - $TITLE.ogg"
			else
				sed -i '1d' $DIR/breakpoints.txt
				START=$LEN
				MIN=${LEN%:*}
				SEC=${LEN#$MIN:}
				SEC=${SEC%.*}
				MIL=${LEN##*.}
				LEN=`head -n 1 $DIR/breakpoints.txt`
				TRACK=`head -n 1 $DIR/songs.txt | sed 's/track number:[\t ]*//'`
				test -z "$2" && ARTIST=`head -n 2 $DIR/songs.txt | tail -n 1 | sed 's/perfomer:[\t ]*//'`
				TITLE=`head -n 3 $DIR/songs.txt | tail -n 1 | sed 's/title:[\t ]*//'`
				YEARS=`echo $CUEFILE | sed 's@^.*/\([0-9]*\( - [0-9]*\)\?\) .*$@\1@'`
				if test -z "$TRACK" -o -z "$ARTIST" -o -z "$TITLE" -o -z "$YEARS" -o -z "$ALBUM"
				then
					printf "Erreur:LEN = $LEN\nTrack = $TRACK\nArtist = $ARTIST\nAlbum=$ALBUM\nTITLE= $TITLE\nYEAR =$YEARS\nFichier:$CUEFILE\n";
					exit
				fi
				sed '1,3d' -i $DIR/songs.txt
				[ -z "$LEN" ] &&break
				PMIN=${LEN%:*}
				PSEC=${LEN#$PMIN:}
				PSEC=${PSEC%.*}
				PMIL=${LEN##*.}
				END=$LEN
				sed -e "s/MINUTES/$MIN/" -e "s/SCS/$SEC/" -e "s/MILLISECONDS/$MIL/" -e 's/HEURE/0/' -i.bak $DIR/bc.script1 || exit
				MYLEN=`bc -q $DIR/bc.script1`
				mv $DIR/bc.script1.bak $DIR/bc.script1
				sed -e "s/MINUTES/$PMIN/" -e "s/SCS/$PSEC/" -e "s/MILLISECONDS/$PMIL/" -e 's/HEURE/0/' -i.bak $DIR/bc.script1 || exit
				_MYLEN_=`bc -q $DIR/bc.script1`
				mv $DIR/bc.script1.bak $DIR/bc.script1
				V=$(($_MYLEN_ - $MYLEN))
				sed "s/TIME/$V/" -i.bak $DIR/bc.script2 || exit
				DURATION=`bc -q $DIR/bc.script2`
				mv $DIR/bc.script2.bak $DIR/bc.script2
				sed -e "s/HEURE/0/" -e "s/SCS/$SEC/" -e "s/MINUTES/$MIN/" -e "s/MILLISECONDS/$MIL/" -i.bak $DIR/bc.script1
				X=`bc -q $DIR/bc.script1`
				sed -e "s/TIME/$X/" -i.bak $DIR/bc.script2
				START=`bc -q $DIR/bc.script2`
				mv $DIR/bc.script1.bak $DIR/bc.script1
				mv $DIR/bc.script2.bak $DIR/bc.script2
				encode 1 $DURATION "$START" "${CUEFILE%*.cue}.flac" "$OUTDIR"/"$ARTIST - $YEARS - $ALBUM - $TRACK - $TITLE.ogg"
			fi
		done
		YEARS=`echo $CUEFILE | sed 's@^.*/\([0-9]*\( - [0-9]*\)\?\) .*$@\1@'`
		MIN=${END%:*}
		SEC=${END#$MIN:}
		SEC=${SEC%.*}
		MIL=${END##*.}
		if test -z "$TRACK" -o -z "$ARTIST" -o -z "$TITLE" -o -z "$YEARS" -o -z "$ALBUM"
		then
			printf "Erreur:\nTrack = $TRACK\nArtist = $ARTIST\nAlbum=$ALBUM\nTITLE= $TITLE\nYEAR =$YEARS\nFichier:$CUEFILE\n";
			exit
		fi
		sed -e "s/HEURE/0/" -e "s/SCS/$SEC/" -e "s/MINUTES/$MIN/" -e "s/MILLISECONDS/$MIL/" -i.bak $DIR/bc.script1
		X=`bc -q $DIR/bc.script1`
		sed -e "s/TIME/$X/" -i.bak $DIR/bc.script2
		START=`bc $DIR/bc.script2`
		mv $DIR/bc.script1.bak $DIR/bc.script1
		mv $DIR/bc.script2.bak $DIR/bc.script2
		encode 2 $START "${CUEFILE%*.cue}.flac" "$OUTDIR"/"$ARTIST - $YEARS - $ALBUM - $TRACK - $TITLE.ogg"
	fi
done < $DIR/list.cue
. $DIR/src
rm -r $DIR

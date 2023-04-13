#!/bin/sh
OUTDIR=~/"la Music"
ARTIST="$2"
if test "$1" = "clear"
then
	rm /tmp/src /tmp/bc.script1 /tmp/bc.script2 /tmp/list.cue /tmp/songs.txt /tmp/breakpoints.txt
	exit
fi
[ -e /tmp/bc.script1 ] && rm /tmp/bc.script1
[ -e /tmp/bc.script2 ] && rm /tmp/bc.script2
test -d "$OUTDIR" || mkdir "$OUTDIR"
cat << EOF >> /tmp/bc.script1
h = HEURE
m = MILLISECONDS
s = SCS
x = MINUTES
r = h*60*60*100+x*60*100+s*100+m
print r
quit 
EOF
cat << EOF >>/tmp/bc.script2
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
		echo "ffmpeg -t \"$2\" -i \"$3\" -ar 48000 -vn -codec:a libvorbis -qscale:a 7 \"$4\"" >> /tmp/src
	;;
	1)
		echo "ffmpeg -t \"$2\" -ss \"$3\" -i \"$4\" -ar 48000 -vn -codec:a libvorbis -qscale:a 7 \"$5\"" >>/tmp/src
	;;
	2)
		echo "ffmpeg -ss \"$2\" -i \"$3\" -ar 48000 -vn -codec:a libvorbis -qscale:a 7 \"$4\" " >> /tmp/src
	;;
	esac
}
find "$1" -name \*.cue >/tmp/list.cue
while read LINE;
do
	CUEFILE="$LINE"
	if [ -e "${CUEFILE%*.cue}.flac" ]
	then
		cuebreakpoints "$LINE" >/tmp/breakpoints.txt
		cueprint "$LINE" | sed -n '/^\(track number\|perfomer\|title\):[\t ]/p' >/tmp/songs.txt
		sed 's@/\(.*\)@ (\1)@' -i /tmp/songs.txt
		ALBUM=`head -n 1 /tmp/songs.txt | sed 's/title:[ \t]*//'`
		LEN=0
		MYLEN=0
		_MYLEN_=0
		sed '1d' -i /tmp/songs.txt
		while [ 1 -eq 1 ];
		do
			if [ "$LEN" = "0" ]
			then
				LEN=`head -n 1 /tmp/breakpoints.txt`
				TRACK=`head -n 1 /tmp/songs.txt | sed 's/track number:[\t ]*//'`
				test -z "$2" && ARTIST=`head -n 2 /tmp/songs.txt | tail -n 1 | sed 's/perfomer:[\t ]*//'`
				TITLE=`head -n 3 /tmp/songs.txt | tail -n 1 | sed 's/title:[\t ]*//'`
				YEARS=`echo $CUEFILE | sed 's@^.*/\([0-9]*\( - [0-9]*\)\?\) .*$@\1@'`
				if test -z "$TRACK" -o -z "$ARTIST" -o -z "$TITLE" -o -z "$YEARS" -o -z "$ALBUM"
				then
					printf "Erreur:\nTrack = $TRACK\nArtist = $ARTIST\nAlbum=$ALBUM\nTITLE= $TITLE\nYEAR =$YEARS\n";
					exit
				fi
				sed '1,3d' -i /tmp/songs.txt
				MIN=${LEN%:*}
				SEC=${LEN#$MIN:}
				SEC=${SEC%.*}
				MIL=${LEN##*.}
				sed -e "s/MINUTES/$MIN/" -e "s/SCS/$SEC/" -e "s/MILLISECONDS/$MIL/" -e 's/HEURE/0/' -i.bak /tmp/bc.script1 || exit
				MYLEN=`bc -q /tmp/bc.script1`
				mv /tmp/bc.script1.bak /tmp/bc.script1
				encode 0 $LEN "${CUEFILE%*.cue}.flac" "$OUTDIR"/"$ARTIST - $YEARS - $ALBUM - $TRACK - $TITLE.ogg"
			else
				sed -i '1d' /tmp/breakpoints.txt
				START=$LEN
				MIN=${LEN%:*}
				SEC=${LEN#$MIN:}
				SEC=${SEC%.*}
				MIL=${LEN##*.}
				LEN=`head -n 1 /tmp/breakpoints.txt`
				TRACK=`head -n 1 /tmp/songs.txt | sed 's/track number:[\t ]*//'`
				test -z "$2" && ARTIST=`head -n 2 /tmp/songs.txt | tail -n 1 | sed 's/perfomer:[\t ]*//'`
				TITLE=`head -n 3 /tmp/songs.txt | tail -n 1 | sed 's/title:[\t ]*//'`
				YEARS=`echo $CUEFILE | sed 's@^.*/\([0-9]*\( - [0-9]*\)\?\) .*$@\1@'`
				if test -z "$TRACK" -o -z "$ARTIST" -o -z "$TITLE" -o -z "$YEARS" -o -z "$ALBUM"
				then
					printf "Erreur:\nTrack = $TRACK\nArtist = $ARTIST\nAlbum=$ALBUM\nTITLE= $TITLE\nYEAR =$YEARS\n";
					exit
				fi
				sed '1,3d' -i /tmp/songs.txt
				[ -z "$LEN" ] &&break
				PMIN=${LEN%:*}
				PSEC=${LEN#$PMIN:}
				PSEC=${PSEC%.*}
				PMIL=${LEN##*.}
				END=$LEN
				sed -e "s/MINUTES/$MIN/" -e "s/SCS/$SEC/" -e "s/MILLISECONDS/$MIL/" -e 's/HEURE/0/' -i.bak /tmp/bc.script1 || exit
				MYLEN=`bc -q /tmp/bc.script1`
				mv /tmp/bc.script1.bak /tmp/bc.script1
				sed -e "s/MINUTES/$PMIN/" -e "s/SCS/$PSEC/" -e "s/MILLISECONDS/$PMIL/" -e 's/HEURE/0/' -i.bak /tmp/bc.script1 || exit
				_MYLEN_=`bc -q /tmp/bc.script1`
				mv /tmp/bc.script1.bak /tmp/bc.script1
				V=$(($_MYLEN_ - $MYLEN))
				sed "s/TIME/$V/" -i.bak /tmp/bc.script2 || exit
				DURATION=`bc -q /tmp/bc.script2`
				mv /tmp/bc.script2.bak /tmp/bc.script2
				sed -e "s/HEURE/0/" -e "s/SCS/$SEC/" -e "s/MINUTES/$MIN/" -e "s/MILLISECONDS/$MIL/" -i.bak /tmp/bc.script1
				X=`bc -q /tmp/bc.script1`
				sed -e "s/TIME/$X/" -i.bak /tmp/bc.script2
				START=`bc -q /tmp/bc.script2`
				mv /tmp/bc.script1.bak /tmp/bc.script1
				mv /tmp/bc.script2.bak /tmp/bc.script2
				encode 1 $DURATION "$START" "${CUEFILE%*.cue}.flac" "$OUTDIR"/"$ARTIST - $YEARS - $ALBUM - $TRACK - $TITLE.ogg"
			fi
		done
		cat /tmp/songs.txt
		YEARS=`echo $CUEFILE | sed 's@^.*/\([0-9]*\( - [0-9]*\)\?\) .*$@\1@'`
		MIN=${END%:*}
		SEC=${END#$MIN:}
		SEC=${SEC%.*}
		MIL=${END##*.}
		if test -z "$TRACK" -o -z "$ARTIST" -o -z "$TITLE" -o -z "$YEARS" -o -z "$ALBUM"
		then
			printf "Erreur:\nTrack = $TRACK\nArtist = $ARTIST\nAlbum=$ALBUM\nTITLE= $TITLE\nYEAR =$YEARS\n";
			exit
		fi
		sed -e "s/HEURE/0/" -e "s/SCS/$SEC/" -e "s/MINUTES/$MIN/" -e "s/MILLISECONDS/$MIL/" -i.bak /tmp/bc.script1
		X=`bc -q /tmp/bc.script1`
		sed -e "s/TIME/$X/" -i.bak /tmp/bc.script2
		START=`bc /tmp/bc.script2`
		mv /tmp/bc.script1.bak /tmp/bc.script1
		mv /tmp/bc.script2.bak /tmp/bc.script2
		encode 2 $START "${CUEFILE%*.cue}.flac" "$OUTDIR"/"$ARTIST - $YEARS - $ALBUM - $TRACK - $TITLE.ogg"
	fi
done < /tmp/list.cue
. /tmp/src
rm /tmp/src /tmp/bc.script1 /tmp/bc.script2 /tmp/list.cue /tmp/songs.txt /tmp/breakpoints.txt

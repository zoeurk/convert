##exemple De script sed
s@_@ @g
s@ \.@.@
s@\[@(@
s@\]@)@
s@.*\(Abscess\)/\([0-9]\{4\}\)\.\(.*\) (Compilation)/\([0-9]\{2\}\) \(.*\)\.mp3@ARTIST=\1\nYEAR=\2\nALBUM=\3\nTRACK=\4\nTITLE=\5\nMETA="-t Comment=Compilation"\n@
s@.*\(Abscess\)/\([0-9]\{4\}\) \(.*\)/\([0-9]\{2\}\) \(.*\)\.mp3@ARTIST=\1\nYEAR=\2\nALBUM=\3\nTRACK=\4\nTITLE=\5\n@
s@.*\(Abscess\)/\([0-9]\{4\}\)\.\(.*\)/\([0-9]\{2\}\) \(.*\)\.mp3@ARTIST=\1\nYEAR=\2\nALBUM=\3\nTRACK=\4\nTITLE=\5\n@
s@.*\(Abscess\)/\([0-9]\{4\}\) \(.*\)/\([0-9]\{2\}\)\. \1 - \3 - \(.*\)\.mp3@ARTIST=\1\nYEAR=\2\nALBUM=\3\nTRACK=\4\nTITLE=\5\n@
s/(\([a-z]\)/(\U\1/
s/ \+/ /g
s/\(=\| \)\([a-z]\)/\1\U\2/g
/Split/ {
	s/ARTIST=[^\n]*\(.*\)ALBUM=\([^\n]*\) \(Population Reduction\) (Split)\(.*\)TITLE=\(.*\) \(\2\|\3\)/ARTIST=\6\1ALBUM=\2 \3\4TITLE=\5\nMETA="-t Comment=Split"\n/
	s/ARTIST=[^\n]*\(.*\)ALBUM=\([^\n]*\) \([^\n]*\) (Split)\(.*\)TITLE=\(.*\) \(\2\|\3\)/ARTIST=\6\1ALBUM=\2 \3\4TITLE=\5\nMETA="-t Comment=Split"\n/
	s/ARTIST=[^\n]*\(.*\)ALBUM=\([^\n]*\) (Split EP)\(.*\)TITLE=- \(.*\) - \(.*\)/ARTIST=\4\1ALBUM=\2 \3TITLE=\5META="-t Comment=Split EP"\n/
}
s/\(.*\) (EP)\(.*\)$/\1\2META="-t Comment=EP"\n/
s/\n\+/\n/g
:redo
s/\("\| \|=\)\([a-z]\)/\1\U\2/
t redo
s/TITLE=\([^\n]*\)/TITLE=\L\1/g
s/TITLE=\([a-z]\)/TITLE=\U\1/
:META
s/META="\([^"]*\)"\(.*\)\META="\([^\n"]*\)"\(.*\)/META="\1 \3"\2\4/
t META
s/ARTIST=\([^\n]*\)/ARTIST="\1"/
s/ALBUM=\([^\n]*\)/ALBUM="\1"/
s/TITLE=\([^\n]*\)/TITLE="\1"/
p

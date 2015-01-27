#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

OPTIONS:
	-h		Show this message
	-p		file to be preprocessed by SENNA format plain
	-t		file to be preprocessed by SENNA format sgm tags	
EOF
}


FILE=
SENNA_PATH="/home/tools/senna-v2.0"
TAG="<seg>"
while getopts "hp:t:" OPTION # (:) after a variable means you nead a value (stored in $OPTARG) otherwise is a flag
do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		p)
			FILE=$OPTARG
			date
			echo "SENNA PLAIN"
			echo "$SENNA_PATH/senna-linux64 -path $SENNA_PATH/ < $FILE > $FILE.conll"
			$SENNA_PATH/senna-linux64 -path $SENNA_PATH/ < $FILE > $FILE.conll 2> $FILE.log
			echo "SENNA PLAIN DONE"
			date
			;;
		t)
			FILE=$OPTARG
			date
			echo "SENNA"
			echo "tr '\n' ' ' <$FILE | sed -re 's/ <\/seg>/\n/g;s/<[^>]*>/ /g;s/\s+/ /g' | $SENNA_PATH/senna-linux64 -path $SENNA_PATH/ > $FILE.conll 2> $FILE.log "
			tr '\n' ' ' <$FILE | sed -re 's/<\/seg>/\n/g;s/<[^>]*>/ /g' | $SENNA_PATH/senna-linux64 -path $SENNA_PATH/ > $FILE.conll 2> $FILE.log 
			echo "SENNA DONE"
			date
			;;		
		?)
			usage
			exit 1
			;;
	esac
done


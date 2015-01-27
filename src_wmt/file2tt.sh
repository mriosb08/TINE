#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

OPTIONS:
	-h		Show this message
	-p		file to be preprocessed by TT format plain
	-t		file to be preprocessed by TT format sgm tags	
EOF
}


FILE=
TT_PATH="/home/tools/treetagger/2011_jan"
SCRIPTS="/home/tools/scripts"
MODEL="english-par-linux-3.1.bin"
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
			echo "TT PLAIN"
			echo "cat $FILE | $SCRIPTS/2treetagger.pl | $TT_PATH/bin/tree-tagger -token -lemma -no-unknown $TT_PATH/params/$model > $FILE.pos 2> $FILE.log "
			cat $FILE | $SCRIPTS/2treetagger.pl | $TT_PATH/bin/tree-tagger -lemma -no-unknown $TT_PATH/params/$MODEL > $FILE.pos 2> $FILE.tt.log 
			echo "TT PLAIN DONE"
			date
			;;
		t)
			FILE=$OPTARG
			date
			echo "TT"
			echo "tr '\n' ' ' <$FILE | sed -re 's/<\/seg>/\n/g;s/<[^>]*>/ /g'| $SCRIPTS/2treetagger.pl | $TT_PATH/bin/tree-tagger -token -lemma -sgml -eos-tag '</s>' -no-unknown $TT_PATH/params/$MODEL 2> $FILE.tt.log  | sed -re 's/^<\/s>$/#\n/g;s/^<s>$//g' | sed -re '/^$/d;s/^#$//g' > $FILE.pos"
			tr '\n' ' ' <$FILE | sed -re 's/<\/seg>/\n/g;s/<[^>]*>/ /g'| $SCRIPTS/2treetagger.pl | $TT_PATH/bin/tree-tagger -token -lemma -sgml -eos-tag '</s>' -no-unknown $TT_PATH/params/$MODEL 2> $FILE.tt.log  | sed -re 's/^<\/s>$/#\n/g;s/^<s>$//g' | sed -re '/^$/d;s/^#$//g' > $FILE.pos 
			echo "TT DONE"
			date
			;;		
		?)
			usage
			exit 1
			;;
	esac
done


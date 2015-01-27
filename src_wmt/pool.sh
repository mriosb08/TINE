#!/bin/bash

declare -f parallelize

# prints instructions
usage()
{
cat << EOF
usage: $0 options

OPTIONS:
	-h		Show this message
	-p		Time for make a pause (default: 1s)
	-n		Number of cpus (default: 2)
	-d		Directory from where commands should be run
	-f		* Commands from a file
EOF
}



PAUSE=1
CPUS=2
CMDS=
FILE=
DIR="./"
I=0
while getopts "hp:n:d:f:" OPTION # (:) after a variable means you nead a value (stored in $OPTARG) otherwise is a flag
do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		p)
			PAUSE=$OPTARG
			;;
		n)
			CPUS=$OPTARG
			;;
		d)
			DIR=$OPTARG
			;;
		f)
			FILE=$OPTARG
			;;
#		c)
#			CMDS[$I]="$OPTARG"
#			I=$I+1
#			;;
		?)
		usage
		exit
		;;
	esac
done

if [ -z $FILE ]
then
	usage
	exit
fi

if [ ! -f $FILE ]
then
	usage
	exit
fi

echo "pool> pause $PAUSE"
echo "pool> cpus $CPUS"
echo "pool> dir $DIR"
cd $DIR
#N=${#CMDS[@]}
running=0
launched=0
i=0
cat $FILE | while task=`line`
do
	i=`expr $i + 1`
	launched=`expr $i + 1`
	echo "pool> $i: $task"
	eval "$task&"
	running=" $(jobs -pr | wc -l)"
	echo "pool> running $running launched $launched" >&2
	while [ "$running" -eq "$CPUS" ]
	do
		sleep $PAUSE
		before=$running
		running=" $(jobs -pr | wc -l)"
		if [ "$before" -gt "$running" ]; then
			echo "pool> running $running launched $launched" >&2
		fi
	done
done

if [ "$running" -ne "0" ]; then
	echo "pool> running $running launched $launched" >&2
	echo "pool> waiting last jobs..." >&2
	wait
	finished=`expr $finished + $running`
	left=`expr $N - $finished`
	running=0
fi
echo "pool> running $running launched $launched" >&2
echo "pool> done" >&2

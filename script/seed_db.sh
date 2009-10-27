#!/bin/bash

function usage {
    echo "Usage:"
    echo "$0 -e RAILS_ENV -d /path/to/rails/app -r /path/to/rake/command/rake -n number_of_events_per_culture_provider -c number_of_culture_providers"
    echo "defaults values: -d . -e development -r $(which rake) -n 3 -c 10"
}

echo "start"

argparse="option"

for arg in $*
do
    if [ $argparse = "option" ]; then
	if [ "${arg:0:1}" = '-' ]; then
	    argparse=$arg
	else 
	    echo "no options"
	    usage
	    exit -1
	fi
    else
	case $argparse in
	    "-c")
		numcps=$arg
		argparse="option"
		;;
	    "-n")
		numevents=$arg
		argparse="option"
		;;
	    "-d")
		railsdir=$arg
		if [ ! -d $railsdir ]; then
		    echo "$railsdir is not a directory"
		    usage
		    exit -1
		fi
		echo "RAILS_DIR = $railsdir"
		argparse="option"
		;;
	    "-e")
		railsenv=$arg
		echo "RAILS_ENV = $railsenv"
		argparse="option"
		;;
	    "-r")
		rake=$arg
		if [ ! -x $rake ]; then
		    echo "$rake is not a executable"
		    usage
		    exit -1
		fi
		argparse="option"
		;;
	    *)
		usage
		exit -1
		;;
	esac
    fi
done

echo "done parsing"

if [ -z $railsdir ]; then
    railsdir=$(pwd)
fi
if [ ! -d ${railsdir}/lib/tasks ]; then
    echo "$railsdir is not a railsapp directory"
    usage
    exit -1
fi
if [ -z $railsenv ]; then
    railsenv="development"
fi
if [ -z $rake ]; then
    rake=$(which rake)
    if [ ! -x $rake ]; then
	echo "No valid rake command found"
	usage
	exit -1
    fi
fi

if [ -z $numevents ]; then
    numevents=3
fi

if [ -z $numcps ]; then
    numcps=10
fi

cd $railsdir
$rake RAILS_ENV=${railsenv} db:drop
if [ $? -ne "0" ]; then
    echo "Unable to drop database - STOP"
    exit -1
fi
$rake RAILS_ENV=${railsenv} db:create
if [ $? -ne "0" ]; then
    echo "Unable to create database - STOP"
    exit -1
fi
$rake RAILS_ENV=${railsenv} db:migrate
if [ $? -ne "0" ]; then
    echo "Unable to migrate database - STOP"
    exit -1
fi
$rake RAILS_ENV=${railsenv} kp:bootstrap
if [ $? -ne "0" ]; then
    echo "Unable to bootstrap application"
    exit -1
fi

$rake RAILS_ENV=${railsenv} kp:demo:create_categories
if [ $? -ne "0" ]; then
    echo "Unable to bootstrap application"
    exit -1
fi

$rake RAILS_ENV=${railsenv} kp:demo:create_group_structure
if [ $? -ne "0" ]; then
    echo "Unable to bootstrap application"
    exit -1
fi

for i in $(seq $numcps)
do
    $rake RAILS_ENV=${railsenv} kp:demo:generate_culture_provider
done

for i in $(seq $numcps )
do
    for j in $(seq $numevents)
    do
	$rake RAILS_ENV=${railsenv} kp:demo:generate_event culture_provider_id=$i
    done
    $rake RAILS_ENV=${railsenv} kp:demo:generate_standing_event culture_provider_id=$i
done

for i in $(seq $(( $numcps * $numevents)) )
do
    $rake RAILS_ENV=${railsenv} kp:demo:create_tickets event_id=$i
done

$rake RAILS_ENV=${railsenv} kp:demo:create_questions

for i in $(seq $(( $numcps * $numevents)) )
do
    $rake RAILS_ENV=${railsenv} kp:demo:create_questionnaires event_id=$i
done

exit 0

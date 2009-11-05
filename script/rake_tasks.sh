#!/bin/bash

. /etc/profile

RAILS_DIR=$1
RAILS_ENV=$2

if [ -z $RAILS_DIR ]; then
   RAILS_DIR=/srv/rails/kp-dev
fi

if [ -z $RAILS_ENV ]; then
   RAILS_ENV=development
fi   

RAKE=/usr/local/bin/rake
if [ ! -x $RAKE ]; then
   echo "Can not find rake"
   exit -1
fi   

if [ ! -d $RAILS_DIR/lib/tasks ]; then
   echo "No rails-dir $RAILS_DIR"
   exit -1
fi   

echo -n "Begin rake tasks KP, RAILS_ENV=$RAILS_ENV at "
date
$RAKE RAILS_ENV=$RAILS_ENV kp:notify_occasion_reminder 
$RAKE RAILS_ENV=$RAILS_ENV kp:notify_ticket_release
$RAKE RAILS_ENV=$RAILS_ENV kp:remind_answer_form 
$RAKE RAILS_ENV=$RAILS_ENV kp:send_answer_forms 
$RAKE RAILS_ENV=$RAILS_ENV kp:update_tickets 

echo -n "all tasks done at "
date

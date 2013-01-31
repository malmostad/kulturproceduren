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


if [ ! -d $RAILS_DIR/lib/tasks ]; then
   echo "No rails-dir $RAILS_DIR"
   exit -1
fi

cd $RAILS_DIR

echo -n "Begin rake tasks KP, RAILS_ENV=$RAILS_ENV at "
date
bundle exec rake RAILS_ENV=$RAILS_ENV kp:cleanup:orphan_companions
bundle exec rake RAILS_ENV=$RAILS_ENV kp:notify_occasion_reminder
bundle exec rake RAILS_ENV=$RAILS_ENV kp:notify_ticket_release
bundle exec rake RAILS_ENV=$RAILS_ENV kp:remind_answer_form
bundle exec rake RAILS_ENV=$RAILS_ENV kp:send_answer_forms
bundle exec rake RAILS_ENV=$RAILS_ENV kp:update_tickets

echo -n "all tasks done at "
date

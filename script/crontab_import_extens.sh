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

echo -n "Begin crontab task to import files from Extens, RAILS_ENV=$RAILS_ENV at "
date

/home/kp-production/.rbenv/shims/bundle exec rake RAILS_ENV=$RAILS_ENV kk:extens:ftp_import

echo -n "Tasks done at "
date

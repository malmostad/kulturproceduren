#!/bin/bash

. /etc/profile

RAILS_ENV=development

RAKE=/usr/local/bin/rake

echo -n "Begin rake tasks KP, RAILS_ENV=$RAILS_ENV at "
date
$RAKE RAILS_ENV=$RAILS_ENV kp:notify_occasion_reminder 
$RAKE RAILS_ENV=$RAILS_ENV kp:notify_ticket_release
$RAKE RAILS_ENV=$RAILS_ENV kp:remind_answer_form 
$RAKE RAILS_ENV=$RAILS_ENV kp:send_answer_forms 
$RAKE RAILS_ENV=$RAILS_ENV kp:update_tickets 

echo -n "all tasks done at "
date

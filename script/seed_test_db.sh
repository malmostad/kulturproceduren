#!/bin/bash

RAKE=/usr/bin/rake

export RALS_ENV=development

cd /srv/rails/kp-test/
/etc/init.d/pgsql restart
$RAKE RAILS_ENV=development db:drop
$RAKE RAILS_ENV=development db:create
$RAKE RAILS_ENV=development db:migrate
$RAKE RAILS_ENV=development kp:bootstrap
$RAKE RAILS_ENV=development kp:demo:create_categories
$RAKE RAILS_ENV=development kp:demo:create_group_structure
$RAKE RAILS_ENV=development kp:demo:generate_culture_provider
$RAKE RAILS_ENV=development kp:demo:generate_culture_provider
$RAKE RAILS_ENV=development kp:demo:generate_culture_provider
$RAKE RAILS_ENV=development kp:demo:generate_culture_provider
$RAKE RAILS_ENV=development kp:demo:generate_culture_provider
$RAKE RAILS_ENV=development kp:demo:generate_culture_provider
$RAKE RAILS_ENV=development kp:demo:generate_culture_provider
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=1
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=1
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=2
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=2
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=3
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=3
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=4
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=4
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=5
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=5
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=6
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=6
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=7
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=7
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=8
$RAKE RAILS_ENV=development kp:demo:generate_event culture_provider_id=8
$RAKE RAILS_ENV=development kp:demo:generate_standing_event culture_provider_id=1
$RAKE RAILS_ENV=development kp:demo:generate_standing_event culture_provider_id=2
$RAKE RAILS_ENV=development kp:demo:generate_standing_event culture_provider_id=3
$RAKE RAILS_ENV=development kp:demo:generate_standing_event culture_provider_id=4
$RAKE RAILS_ENV=development kp:demo:generate_standing_event culture_provider_id=5
$RAKE RAILS_ENV=development kp:demo:generate_standing_event culture_provider_id=6
$RAKE RAILS_ENV=development kp:demo:generate_standing_event culture_provider_id=7
$RAKE RAILS_ENV=development kp:demo:generate_standing_event culture_provider_id=8
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=1
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=2
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=3
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=4
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=5
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=6
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=7
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=8
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=9
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=10
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=11
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=12
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=13
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=14
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=15
$RAKE RAILS_ENV=development kp:demo:create_tickets event_id=16
$RAKE RAILS_ENV=development kp:demo:create_questions
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=1
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=2
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=3
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=4
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=5
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=6
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=7
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=8
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=9
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=10
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=11
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=12
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=13
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=14
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=15
$RAKE RAILS_ENV=development kp:demo:create_questionnaires event_id=16



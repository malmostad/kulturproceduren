class AddForeignKeys < ActiveRecord::Migration
  def self.up
    #
    execute 'ALTER TABLE notification_requests ADD CONSTRAINT fk_occasion FOREIGN KEY ( occasion_id ) REFERENCES occasions(id)'
    execute 'ALTER TABLE notification_requests ADD CONSTRAINT fk_group FOREIGN KEY ( group_id ) REFERENCES groups(id)'
    #
    execute 'ALTER TABLE groups ADD CONSTRAINT fk_school FOREIGN KEY ( school_id ) REFERENCES schools(id)'
    execute 'ALTER TABLE schools ADD CONSTRAINT fk_district FOREIGN KEY ( district_id ) REFERENCES districts(id)'
    #
    execute 'ALTER TABLE tickets ADD CONSTRAINT fk_group FOREIGN KEY ( group_id ) REFERENCES groups(id)'
    execute 'ALTER TABLE tickets ADD CONSTRAINT fk_district FOREIGN KEY ( district_id ) REFERENCES districts(id)'
    execute 'ALTER TABLE tickets ADD CONSTRAINT fk_event FOREIGN KEY ( event_id ) REFERENCES events(id)'
    #
    #execute 'ALTER TABLE ADD CONSTRAINT fk_ FOREIGN KEY ( _id ) REFERENCES (id)'
    #execute 'ALTER TABLE ADD CONSTRAINT fk_ FOREIGN KEY ( _id ) REFERENCES (id)'
    #
    execute 'ALTER TABLE occasions ADD CONSTRAINT fk_event FOREIGN KEY ( event_id ) REFERENCES events(id)'
    #
    execute 'ALTER TABLE booking_requirements ADD CONSTRAINT fk_group FOREIGN KEY ( group_id ) REFERENCES groups(id)'
    execute 'ALTER TABLE booking_requirements ADD CONSTRAINT fk_occasion FOREIGN KEY ( occasion_id ) REFERENCES occasions(id)'
    #
    execute 'ALTER TABLE age_groups ADD CONSTRAINT fk_group FOREIGN KEY ( group_id ) REFERENCES groups(id)'
    #
#    execute 'ALTER TABLE culture_administrator_group ADD CONSTRAINT fk_culture_administrator FOREIGN KEY ( culture_administrator_id ) REFERENCES culture_administrators(id)'
#    execute 'ALTER TABLE culture_administrator_group ADD CONSTRAINT fk_group FOREIGN KEY ( group_id ) REFERENCES groups(id)'
  end

  def self.down
    execute 'ALTER TABLE notification_requests DROP CONSTRAINT fk_occasion '
    execute 'ALTER TABLE notification_requests DROP CONSTRAINT fk_group '
    #
    execute 'ALTER TABLE groups DROP CONSTRAINT fk_school '
    execute 'ALTER TABLE schools DROP CONSTRAINT fk_district '
    #
    execute 'ALTER TABLE tickets DROP CONSTRAINT fk_group '
    execute 'ALTER TABLE tickets DROP CONSTRAINT fk_district '
    execute 'ALTER TABLE tickets DROP CONSTRAINT fk_event '
    #
    #execute 'ALTER TABLE DROP CONSTRAINT fk_ FOREIGN KEY ( _id ) REFERENCES (id)'
    #execute 'ALTER TABLE DROP CONSTRAINT fk_ FOREIGN KEY ( _id ) REFERENCES (id)'
    #
    execute 'ALTER TABLE occasions DROP CONSTRAINT fk_event '
    #
    execute 'ALTER TABLE booking_requirements DROP CONSTRAINT fk_group '
    execute 'ALTER TABLE booking_requirements DROP CONSTRAINT fk_occasion '
    #
    execute 'ALTER TABLE age_groups DROP CONSTRAINT fk_group '
    #
#    execute 'ALTER TABLE culture_administrator_group DROP CONSTRAINT fk_culture_administrator '
#    execute 'ALTER TABLE culture_administrator_group DROP CONSTRAINT fk_group '

  end
end

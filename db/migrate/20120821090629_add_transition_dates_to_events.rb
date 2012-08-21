class AddTransitionDatesToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :district_transition_date, :date
    add_column :events, :free_for_all_transition_date, :date

    Event.find_each(:conditions => "ticket_release_date is not null") do |event|
      event.district_transition_date = event.ticket_release_date + APP_CONFIG[:ticket_state][:group_days]
      event.free_for_all_transition_date = event.ticket_release_date + APP_CONFIG[:ticket_state][:group_days] + APP_CONFIG[:ticket_state][:district_days]
      event.save!
    end
  end

  def self.down
    remove_column :events, :district_transition_date
    remove_column :events, :free_for_all_transition_date
  end
end

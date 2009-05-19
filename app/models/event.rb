class Event < ActiveRecord::Base
  has_many                :tickets
  has_many                :occasions
  has_and_belongs_to_many :tags
  belongs_to              :culture_provider
  has_one                 :questionaire

  validates_presence_of :from_age, :to_age, :description

  def self.visible_events_by_userid(u)
    today = Date.today
    u = u.to_i
    events = Event.find_by_sql "select * from events where show_date < '#{today.to_s}' and id in ( select distinct event_id from tickets,groups_users where user_id=#{u} and tickets.group_id = groups_users.group_id)"
    return events
  end
end

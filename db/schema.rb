# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091027103239) do

  create_table "age_groups", :force => true do |t|
    t.integer  "age"
    t.integer  "quantity"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "answer_forms", :id => false, :force => true do |t|
    t.string   "id",              :limit => 46, :null => false
    t.boolean  "completed"
    t.integer  "companion_id"
    t.integer  "occasion_id"
    t.integer  "group_id"
    t.integer  "questionaire_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "answers", :force => true do |t|
    t.integer  "question_id"
    t.string   "answer_form_id", :limit => 46
    t.text     "answer_text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "attachments", :force => true do |t|
    t.integer  "event_id"
    t.string   "description"
    t.string   "filename"
    t.string   "content_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "booking_requirements", :force => true do |t|
    t.text     "requirement"
    t.integer  "occasion_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", :force => true do |t|
    t.integer  "category_group_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories_events", :id => false, :force => true do |t|
    t.integer "category_id"
    t.integer "event_id"
  end

  add_index "categories_events", ["category_id", "event_id"], :name => "index_categories_events_on_category_id_and_event_id", :unique => true

  create_table "category_groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "visible_in_calendar", :default => true
  end

  create_table "companions", :force => true do |t|
    t.string   "tel_nr"
    t.string   "email"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "culture_providers", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "contact_person"
    t.string   "email"
    t.string   "phone"
    t.text     "address"
    t.text     "opening_hours"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "main_image_id"
    t.string   "map_address"
    t.boolean  "active",         :default => true
  end

  create_table "culture_providers_users", :id => false, :force => true do |t|
    t.integer "culture_provider_id"
    t.integer "user_id"
  end

  create_table "districts", :force => true do |t|
    t.string   "name"
    t.string   "contacts"
    t.string   "elit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "event_links", :id => false, :force => true do |t|
    t.integer "from_id"
    t.integer "to_id"
  end

  add_index "event_links", ["from_id", "to_id"], :name => "index_event_links_on_from_id_and_to_id"

  create_table "events", :force => true do |t|
    t.integer  "culture_provider_id"
    t.string   "name"
    t.text     "description"
    t.date     "visible_from"
    t.date     "visible_to"
    t.integer  "from_age"
    t.integer  "to_age"
    t.boolean  "further_education",   :default => false
    t.date     "ticket_release_date"
    t.integer  "ticket_state"
    t.string   "url"
    t.string   "movie_url"
    t.text     "opening_hours"
    t.text     "cost"
    t.string   "booking_info"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "main_image_id"
    t.string   "map_address"
  end

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.string   "contacts"
    t.string   "elit_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", :force => true do |t|
    t.integer  "event_id"
    t.integer  "culture_provider_id"
    t.string   "name"
    t.string   "filename"
    t.integer  "width"
    t.integer  "height"
    t.integer  "thumb_width"
    t.integer  "thumb_height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notification_requests", :force => true do |t|
    t.integer  "event_id"
    t.integer  "group_id"
    t.integer  "user_id"
    t.boolean  "send_mail"
    t.boolean  "send_sms"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "occasions", :force => true do |t|
    t.integer  "event_id"
    t.date     "date"
    t.time     "start_time"
    t.time     "stop_time"
    t.integer  "seats"
    t.integer  "wheelchair_seats", :default => 0
    t.text     "address"
    t.text     "description"
    t.boolean  "telecoil"
    t.boolean  "cancelled",        :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "map_address"
  end

  create_table "questionaires", :force => true do |t|
    t.integer  "event_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "questionaires_questions", :id => false, :force => true do |t|
    t.integer "question_id"
    t.integer "questionaire_id"
  end

  add_index "questionaires_questions", ["questionaire_id", "question_id"], :name => "qq_idx", :unique => true

  create_table "questions", :force => true do |t|
    t.string   "qtype"
    t.string   "question"
    t.string   "choice_csv"
    t.boolean  "template"
    t.boolean  "mandatory"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "role_applications", :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.integer  "group_id"
    t.integer  "culture_provider_id"
    t.text     "message"
    t.text     "new_culture_provider_name"
    t.integer  "state"
    t.text     "response"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "school_prios", :force => true do |t|
    t.integer  "prio"
    t.integer  "school_id"
    t.integer  "district_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "schools", :force => true do |t|
    t.string   "name"
    t.string   "contacts"
    t.string   "elit_id"
    t.integer  "district_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :limit => 512, :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "tickets", :force => true do |t|
    t.integer  "state"
    t.integer  "group_id"
    t.integer  "event_id"
    t.integer  "occasion_id"
    t.integer  "district_id"
    t.integer  "companion_id"
    t.integer  "user_id"
    t.boolean  "adult"
    t.boolean  "wheelchair",   :default => false
    t.datetime "booked_when"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tickets", ["event_id"], :name => "index_tickets_on_event_id"
  add_index "tickets", ["group_id"], :name => "index_tickets_on_group_id"

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "password"
    t.string   "salt"
    t.string   "name"
    t.string   "email"
    t.string   "cellphone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_active"
    t.string   "request_key"
  end

  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

end

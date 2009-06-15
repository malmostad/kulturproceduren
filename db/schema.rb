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

ActiveRecord::Schema.define(:version => 20090615114835) do

  create_table "age_groups", :force => true do |t|
    t.integer  "age"
    t.integer  "quantity"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "answer_forms", :force => true do |t|
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
    t.integer  "answer"
    t.string   "answer_text"
    t.integer  "occasion_id"
    t.string   "answer_form_id", :limit => 46
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

  create_table "companions", :force => true do |t|
    t.string   "tel_nr"
    t.string   "email"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "culture_administrators_users", :id => false, :force => true do |t|
    t.integer "culture_administrator_id"
    t.integer "user_id"
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
  end

  create_table "culture_providers_users", :id => false, :force => true do |t|
    t.integer "culture_provider_id"
    t.integer "user_id"
  end

  create_table "districts", :force => true do |t|
    t.string   "name"
    t.integer  "elit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "districts_users", :id => false, :force => true do |t|
    t.integer "district_id"
    t.integer "user_id"
  end

  create_table "events", :force => true do |t|
    t.integer  "culture_provider_id"
    t.string   "name"
    t.text     "description"
    t.date     "show_date"
    t.integer  "from_age"
    t.integer  "to_age"
    t.integer  "ticket_state"
    t.string   "url"
    t.string   "movie_url"
    t.text     "opening_hours"
    t.text     "cost"
    t.string   "booking_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "main_image_id"
  end

  create_table "events_tags", :id => false, :force => true do |t|
    t.integer "event_id"
    t.integer "tag_id"
  end

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.integer  "elit_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups_users", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "user_id"
  end

  create_table "images", :force => true do |t|
    t.integer  "event_id"
    t.integer  "culture_provider_id"
    t.string   "name"
    t.string   "filename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notification_requests", :force => true do |t|
    t.boolean  "send_mail"
    t.boolean  "send_sms"
    t.integer  "group_id"
    t.integer  "occasion_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "occasions", :force => true do |t|
    t.integer  "event_id"
    t.date     "date"
    t.time     "start_time"
    t.time     "stop_time"
    t.integer  "seats"
    t.integer  "wheelchair_seats"
    t.text     "address"
    t.text     "description"
    t.boolean  "telecoil"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "occasions_users", :id => false, :force => true do |t|
    t.integer "occasion_id"
    t.integer "user_id"
  end

  create_table "question_mchoices", :force => true do |t|
    t.boolean  "template"
    t.string   "question"
    t.string   "choices_csv"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "question_normals", :force => true do |t|
    t.boolean  "template"
    t.string   "question"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.integer  "elit_id"
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

  create_table "tags", :force => true do |t|
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tickets", :force => true do |t|
    t.integer  "state"
    t.integer  "group_id"
    t.integer  "event_id"
    t.integer  "occasion_id"
    t.integer  "district_id"
    t.integer  "companion_id"
    t.boolean  "adult"
    t.integer  "user_id"
    t.boolean  "wheelchair",   :default => false
    t.datetime "booked_when"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "password"
    t.string   "salt"
    t.string   "name"
    t.string   "email"
    t.string   "mobil_nr"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

end

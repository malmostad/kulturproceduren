# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170120122812) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "age_categories", force: true do |t|
    t.string   "name",              limit: 40
    t.integer  "from_age",                                     null: false
    t.integer  "to_age",                                       null: false
    t.boolean  "further_education",            default: false, null: false
    t.integer  "sort_order",                   default: 0,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "age_groups", force: true do |t|
    t.integer  "age"
    t.integer  "quantity"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "to_delete"
  end

  create_table "allotments", force: true do |t|
    t.integer  "amount"
    t.integer  "user_id"
    t.integer  "event_id"
    t.integer  "district_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "school_id"
    t.integer  "excluded_district_ids", default: [], array: true
  end

  add_index "allotments", ["school_id"], name: "index_allotments_on_school_id", using: :btree

  create_table "answer_forms", force: true do |t|
    t.boolean  "completed"
    t.integer  "occasion_id"
    t.integer  "group_id"
    t.integer  "questionnaire_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "booking_id"
  end

  create_table "answers", force: true do |t|
    t.integer  "question_id"
    t.string   "answer_form_id", limit: 46
    t.text     "answer_text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "attachments", force: true do |t|
    t.integer  "event_id"
    t.string   "description"
    t.string   "filename"
    t.string   "content_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "backup_merged_answers", id: false, force: true do |t|
    t.integer  "id"
    t.integer  "question_id"
    t.string   "answer_form_id", limit: 46
    t.text     "answer_text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "booking_requirements", force: true do |t|
    t.text     "requirement"
    t.integer  "occasion_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bookings", force: true do |t|
    t.datetime "booked_at"
    t.boolean  "unbooked",                default: false
    t.datetime "unbooked_at"
    t.integer  "unbooked_by_id"
    t.integer  "student_count"
    t.integer  "adult_count"
    t.integer  "wheelchair_count"
    t.text     "requirement"
    t.string   "companion_name"
    t.string   "companion_phone"
    t.string   "companion_email"
    t.integer  "group_id"
    t.integer  "occasion_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "bus_booking",             default: false
    t.boolean  "bus_one_way",             default: false
    t.string   "bus_stop"
    t.integer  "bus_booster_seats_count", default: 0
  end

  create_table "categories", force: true do |t|
    t.integer  "category_group_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories_events", id: false, force: true do |t|
    t.integer "category_id"
    t.integer "event_id"
  end

  add_index "categories_events", ["category_id", "event_id"], name: "index_categories_events_on_category_id_and_event_id", unique: true, using: :btree

  create_table "category_groups", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "visible_in_calendar", default: true
  end

  create_table "companions", force: true do |t|
    t.string   "tel_nr"
    t.string   "email"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "culture_provider_links", id: false, force: true do |t|
    t.integer "from_id"
    t.integer "to_id"
  end

  add_index "culture_provider_links", ["from_id", "to_id"], name: "index_culture_provider_links_on_from_id_and_to_id", using: :btree

  create_table "culture_providers", force: true do |t|
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
    t.boolean  "active",         default: true
  end

  create_table "culture_providers_events", id: false, force: true do |t|
    t.integer "culture_provider_id"
    t.integer "event_id"
  end

  add_index "culture_providers_events", ["culture_provider_id", "event_id"], name: "cp_ev_id", using: :btree

  create_table "culture_providers_users", id: false, force: true do |t|
    t.integer "culture_provider_id"
    t.integer "user_id"
  end

  create_table "districts", force: true do |t|
    t.string   "name"
    t.string   "contacts"
    t.string   "elit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "extens_id",      limit: 64
    t.integer  "school_type_id"
    t.boolean  "to_delete"
  end

  add_index "districts", ["extens_id"], name: "index_districts_on_extens_id", using: :btree

  create_table "districts_users", id: false, force: true do |t|
    t.integer "district_id"
    t.integer "user_id"
  end

  add_index "districts_users", ["district_id", "user_id"], name: "district_user_id", using: :btree

  create_table "event_links", id: false, force: true do |t|
    t.integer "from_id"
    t.integer "to_id"
  end

  add_index "event_links", ["from_id", "to_id"], name: "index_event_links_on_from_id_and_to_id", using: :btree

  create_table "events", force: true do |t|
    t.integer  "culture_provider_id"
    t.string   "name"
    t.text     "description"
    t.date     "visible_from"
    t.date     "visible_to"
    t.integer  "from_age"
    t.integer  "to_age"
    t.boolean  "further_education",            default: false
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
    t.boolean  "single_group_per_occasion",    default: false
    t.date     "district_transition_date"
    t.date     "free_for_all_transition_date"
    t.boolean  "bus_booking",                  default: false
    t.date     "last_bus_booking_date"
    t.date     "school_transition_date"
    t.integer  "excluded_district_ids",        default: [],    array: true
    t.string   "youtube_url"
    t.date     "last_transitioned_date"
  end

  add_index "events", ["last_transitioned_date"], name: "index_events_on_last_transitioned_date", using: :btree

  create_table "events_school_types", force: true do |t|
    t.integer "event_id"
    t.integer "school_type_id"
  end

  create_table "groups", force: true do |t|
    t.string   "name"
    t.string   "contacts"
    t.string   "elit_id"
    t.integer  "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",                default: true
    t.integer  "priority"
    t.string   "extens_id",  limit: 64
    t.boolean  "to_delete"
  end

  add_index "groups", ["extens_id"], name: "index_groups_on_extens_id", using: :btree

  create_table "images", force: true do |t|
    t.integer  "event_id"
    t.integer  "culture_provider_id"
    t.string   "description"
    t.string   "filename"
    t.integer  "width"
    t.integer  "height"
    t.integer  "thumb_width"
    t.integer  "thumb_height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notification_requests", force: true do |t|
    t.integer  "event_id"
    t.integer  "group_id"
    t.integer  "user_id"
    t.boolean  "send_mail"
    t.boolean  "send_sms"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "target_cd"
  end

  create_table "occasions", force: true do |t|
    t.integer  "event_id"
    t.date     "date"
    t.time     "start_time"
    t.time     "stop_time"
    t.integer  "seats"
    t.integer  "wheelchair_seats", default: 0
    t.text     "address"
    t.text     "description"
    t.boolean  "telecoil"
    t.boolean  "cancelled",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "map_address"
    t.boolean  "single_group",     default: false
  end

  create_table "questionnaires", force: true do |t|
    t.integer  "event_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "target_cd"
  end

  create_table "questionnaires_questions", id: false, force: true do |t|
    t.integer "question_id"
    t.integer "questionnaire_id"
  end

  add_index "questionnaires_questions", ["questionnaire_id", "question_id"], name: "qq_idx", unique: true, using: :btree

  create_table "questions", force: true do |t|
    t.string   "qtype"
    t.string   "question"
    t.string   "choice_csv"
    t.boolean  "template"
    t.boolean  "mandatory"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "role_applications", force: true do |t|
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

  create_table "roles", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", id: false, force: true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "school_types", force: true do |t|
    t.string   "name"
    t.boolean  "active",     default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "schools", force: true do |t|
    t.string   "name"
    t.string   "contacts"
    t.string   "elit_id"
    t.integer  "district_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "extens_id",     limit: 64
    t.text     "city_area"
    t.text     "district_area"
    t.boolean  "to_delete"
  end

  add_index "schools", ["extens_id"], name: "index_schools_on_extens_id", using: :btree

  create_table "sessions", force: true do |t|
    t.string   "session_id", limit: 512, null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "tickets", force: true do |t|
    t.integer  "state"
    t.integer  "group_id"
    t.integer  "event_id"
    t.integer  "occasion_id"
    t.integer  "district_id"
    t.integer  "user_id"
    t.boolean  "adult"
    t.boolean  "wheelchair",   default: false
    t.datetime "booked_when"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "booking_id"
    t.integer  "allotment_id"
    t.integer  "school_id"
  end

  add_index "tickets", ["event_id"], name: "index_tickets_on_event_id", using: :btree
  add_index "tickets", ["group_id"], name: "index_tickets_on_group_id", using: :btree
  add_index "tickets", ["school_id"], name: "index_tickets_on_school_id", using: :btree

  create_table "users", force: true do |t|
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

  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "versions", force: true do |t|
    t.string   "item_type",               null: false
    t.integer  "item_id",                 null: false
    t.string   "event",                   null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "extra_data", default: ""
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

end

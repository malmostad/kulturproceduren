class AddForeignKeys < ActiveRecord::Migration
  def self.up
    add_foreign_key :age_groups, :group
    add_foreign_key :groups, :school
    add_foreign_key :schools, :district
    add_foreign_key :school_prios, :school
    add_foreign_key :school_prios, :district

    add_foreign_key :booking_requirements, :occasion
    add_foreign_key :booking_requirements, :group

    add_foreign_key :notification_requests, :group
    add_foreign_key :notification_requests, :occasion
    add_foreign_key :notification_requests, :user

    add_foreign_key :events, :culture_provider
    add_foreign_key :occasions, :event

    add_foreign_key :tickets, :group
    add_foreign_key :tickets, :event
    add_foreign_key :tickets, :occasion
    add_foreign_key :tickets, :district
    add_foreign_key :tickets, :companion
    add_foreign_key :tickets, :user

    add_foreign_key :questionaires, :event
    add_foreign_key :answers, :question
    add_foreign_key :answers, :answer_form
    add_foreign_key :answer_forms, :companion
    add_foreign_key :answer_forms, :occasion
    add_foreign_key :answer_forms, :group
    add_foreign_key :answer_forms, :questionaire
    add_foreign_key :questionaires_questions, :questionaire
    add_foreign_key :questionaires_questions, :question

    add_foreign_key :role_applications, :user
    add_foreign_key :role_applications, :role
    add_foreign_key :role_applications, :group
    add_foreign_key :role_applications, :culture_provider
    add_foreign_key :roles_users, :role
    add_foreign_key :roles_users, :user

    add_foreign_key :culture_providers_users, :culture_provider
    add_foreign_key :culture_providers_users, :user

    add_foreign_key :images, :event
    add_foreign_key :images, :culture_provider

    add_foreign_key :categories, :category_group
    add_foreign_key :categories_events, :category
    add_foreign_key :categories_events, :event

    add_foreign_key :attachments, :event
  end

  def self.down
    remove_foreign_key :age_groups, :group
    remove_foreign_key :groups, :school
    remove_foreign_key :schools, :district
    remove_foreign_key :school_prios, :school
    remove_foreign_key :school_prios, :district

    remove_foreign_key :booking_requirements, :occasion
    remove_foreign_key :booking_requirements, :group

    remove_foreign_key :notification_requests, :group
    remove_foreign_key :notification_requests, :occasion
    remove_foreign_key :notification_requests, :user

    remove_foreign_key :events, :culture_provider
    remove_foreign_key :occasions, :event

    remove_foreign_key :tickets, :group
    remove_foreign_key :tickets, :event
    remove_foreign_key :tickets, :occasion
    remove_foreign_key :tickets, :district
    remove_foreign_key :tickets, :companion
    remove_foreign_key :tickets, :user

    remove_foreign_key :questionaires, :event
    remove_foreign_key :answers, :question
    remove_foreign_key :answers, :answer_form
    remove_foreign_key :answer_forms, :companion
    remove_foreign_key :answer_forms, :occasion
    remove_foreign_key :answer_forms, :group
    remove_foreign_key :answer_forms, :questionaire
    remove_foreign_key :questionaires_questions, :questionaire
    remove_foreign_key :questionaires_questions, :question

    remove_foreign_key :role_applications, :user
    remove_foreign_key :role_applications, :role
    remove_foreign_key :role_applications, :group
    remove_foreign_key :role_applications, :culture_provider
    remove_foreign_key :roles_users, :role
    remove_foreign_key :roles_users, :user

    remove_foreign_key :culture_providers_users, :culture_provider
    remove_foreign_key :culture_providers_users, :user

    remove_foreign_key :images, :event
    remove_foreign_key :images, :culture_provider

    remove_foreign_key :categories, :category_group
    remove_foreign_key :categories_events, :category
    remove_foreign_key :categories_events, :event
    
    remove_foreign_key :attachments, :event
  end

  private

  def self.add_foreign_key(from, to)
    execute "ALTER TABLE #{from} ADD CONSTRAINT fk_#{to} FOREIGN KEY ( #{to}_id ) REFERENCES #{to.to_s.pluralize}(id)"
  end

  def self.remove_foreign_key(from, to)
    execute "ALTER TABLE #{from} DROP CONSTRAINT fk_#{to}"
  end
end

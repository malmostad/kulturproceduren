# -*- encoding : utf-8 -*-
class RenameQuestionaire < ActiveRecord::Migration
  def self.up
    rename_table :questionaires, :questionnaires
    rename_table :questionaires_questions, :questionnaires_questions

    rename_column :answer_forms, :questionaire_id, :questionnaire_id
    rename_column :questionnaires_questions, :questionaire_id, :questionnaire_id
  end

  def self.down
    rename_column :questionnaires_questions, :questionnaire_id, :questionaire_id
    rename_column :answer_forms, :questionnaire_id, :questionaire_id

    rename_table :questionnaires_questions, :questionaires_questions
    rename_table :questionnaires, :questionaires
  end
end

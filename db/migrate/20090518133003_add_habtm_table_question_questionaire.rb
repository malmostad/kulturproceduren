class AddHabtmTableQuestionQuestionaire < ActiveRecord::Migration
  def self.up
    create_table :questionaires_questions, :id => false do |t|
      t.references :question, :questionaire
    end

    add_index :questionaires_questions, [ :category_id, :event_id ], :unique => true
  end

  def self.down
    drop_table :questionaires_questions
  end
end

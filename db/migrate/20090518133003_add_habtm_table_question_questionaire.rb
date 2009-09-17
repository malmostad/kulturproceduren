class AddHabtmTableQuestionQuestionaire < ActiveRecord::Migration
  def self.up
    create_table :questionaires_questions, :id => false do |t|
      t.references :question, :questionaire
    end

    add_index :questionaires_questions,
      [ :questionaire_id, :question_id ],
      :unique => true,
      :name => "qq_idx"
  end

  def self.down
    drop_table :questionaires_questions
  end
end

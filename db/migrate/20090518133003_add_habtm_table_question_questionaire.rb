class AddHabtmTableQuestionQuestionaire < ActiveRecord::Migration
  def self.up
    create_table :questions_questionaires, :id => false do |t|
      t.references :question, :questionaire
    end
  end

  def self.down
    drop_table :questions_questionaires
  end
end

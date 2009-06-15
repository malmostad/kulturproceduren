class CreateQuestionMchoices < ActiveRecord::Migration
  def self.up
    create_table :question_mchoices do |t|
      t.boolean :template
      t.string :question
      t.string :choices_csv

      t.timestamps
    end
  end

  def self.down
    drop_table :question_mchoices
  end
end

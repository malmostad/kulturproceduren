class CreateAnswers < ActiveRecord::Migration
  def self.up
    create_table :answers do |t|
      t.integer :question_id
      t.integer :answer
      t.string  :answer_text
      t.string :answer_form_id, :limit => 46
      
      t.timestamps
    end
  end

  def self.down
    drop_table :answers
  end
end

class CreateQuestions < ActiveRecord::Migration
  def self.up
    create_table :questions do |t|
      t.boolean :template
      t.text :question
      t.timestamps
    end
  end

  def self.down
    drop_table :questions
  end
end

class CreateQuestions < ActiveRecord::Migration
  def self.up
    create_table   :questions do |t|
      t.string     :qtype
      t.string     :question
      t.string     :choice_csv
      t.boolean    :template
      t.boolean    :mandatory
      t.timestamps
    end
  end

  def self.down
    drop_table :questions
  end
end

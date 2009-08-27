class CreateAnswerForms < ActiveRecord::Migration
  def self.up
    create_table :answer_forms, :id => false do |t|
      t.string  :id, :limit => 46
      t.boolean :completed
      t.integer :companion_id
      t.integer :occasion_id
      t.integer :group_id
      t.integer :questionaire_id

      t.timestamps
    end

    execute "alter table answer_forms add primary key (id)"
  end

  def self.down
    drop_table :answer_forms
  end
end

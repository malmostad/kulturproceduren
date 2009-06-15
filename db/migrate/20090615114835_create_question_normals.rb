class CreateQuestionNormals < ActiveRecord::Migration
  def self.up
    create_table :question_normals do |t|
      t.boolean :template
      t.string :question
      t.string :type

      t.timestamps
    end
  end

  def self.down
    drop_table :question_normals
  end
end

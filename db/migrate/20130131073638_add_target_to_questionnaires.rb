# -*- encoding : utf-8 -*-
class AddTargetToQuestionnaires < ActiveRecord::Migration
  def self.up
    # simple_enum column
    add_column :questionnaires, :target_cd, :integer
    Questionnaire.update_all "target_cd = 1" # 1 = Event
  end

  def self.down
    remove_column :questionnaires, :target_cd
  end
end

class AddHabtmJoinTableEventsTags < ActiveRecord::Migration
  def self.up
    create_table :events_tags, :id => false do |t|
      t.references :event, :tag
    end
  end

  def self.down
    drop_table :events_tags
  end
end

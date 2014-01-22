# -*- encoding : utf-8 -*-
class AddIndeciesOnTickets < ActiveRecord::Migration
  def self.up
    add_index(:tickets , :group_id)
    add_index(:tickets , :event_id)
  end

  def self.down
    remove_index(:tickets , :group_id)
    remove_index(:tickets , :event_id)
  end
end

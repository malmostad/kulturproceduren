# -*- encoding : utf-8 -*-
class AddPriorityToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :priority, :integer

    prio = 1

    if defined?(SchoolPrio)
      groups = Group.all(
        include: { school: :school_prio },
        order: "school_prios.prio ASC"
      )
    else
      groups = Group.all(order: "name ASC")
    end

    groups.each do |group|
      group.priority = prio
      group.save!
      prio += 1
    end
  end

  def self.down
    remove_column :groups, :priority
  end
end

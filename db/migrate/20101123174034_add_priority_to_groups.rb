class AddPriorityToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :priority, :integer

    prio = 1

    if defined?(SchoolPrio)
      groups = Group.includes(school: :school_prio)
        .references(:school_prios)
        .order("school_prios.prio ASC")
    else
      groups = Group.order("name ASC")
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

class AddPriorityToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :priority, :integer

    prio = 1

    groups = Group.all(
      :include => { :school => :school_prio },
      :order => "school_prios.prio ASC"
    )

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

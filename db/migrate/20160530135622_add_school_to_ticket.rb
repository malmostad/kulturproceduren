class AddSchoolToTicket < ActiveRecord::Migration
  def change
    add_reference :tickets, :school, index: true
  end
end

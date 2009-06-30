namespace :kp do

  desc "Call all bootstrap tasks"
  task(:bootstrap) do
    Rake::Task["kp:bootstrap:create_system_roles"].invoke
    Rake::Task["kp:bootstrap:create_admin_account"].invoke
  end

  namespace :bootstrap do
    desc "Create system roles if the do not exist"
    task(:create_system_roles => :environment) do
      [:admin, :booker, :culture_worker, :host].each do |role|
        unless Role.find_by_symbol role
          r = Role.new
          r.name = role.to_s
          r.save!
        end
      end
    end

    desc "Create admin account if it does not exist"
    task(:create_admin_account => :environment) do
      unless User.find_by_name "admin"
        u = User.new
        u.username = "admin"
        u.password = "admin"
        u.name = "Admin"
        u.email = "admin@admin.com"
        u.mobil_nr = "0"
        u.save!

        u.roles << Role.find_by_symbol(:admin)
      end
    end
  end
end

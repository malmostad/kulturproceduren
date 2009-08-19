# Bootstrapping methods for the application
namespace :kp do

  desc "Call all bootstrap tasks"
  task(:bootstrap) do
    Rake::Task["kp:bootstrap:create_system_roles"].invoke
    Rake::Task["kp:bootstrap:create_admin_account"].invoke
  end

  namespace :bootstrap do

    # Creates all system roles required in the application
    desc "Create system roles if they do not exist"
    task(:create_system_roles => :environment) do
      [:admin, :booker, :culture_worker, :host].each do |role|
        unless Role.find_by_symbol role
          r = Role.new
          r.name = role.to_s
          r.save!
        end
      end
    end

    # Creates an administrator account in the application
    desc "Create admin account if it does not exist"
    task(:create_admin_account => :environment) do
      unless User.find_by_name "admin"
        u = User.new
        u.username = "admin"
        u.password = "admin"
        u.name = "Admin"
        u.email = "admin@admin.com"
        u.cellphone = "0"
        u.save!

        u.roles << Role.find_by_symbol(:admin)
      end
    end
  end
end

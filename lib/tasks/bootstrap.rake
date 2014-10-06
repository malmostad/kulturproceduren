# Bootstrapping methods for the application
namespace :kp do

  desc "Call all bootstrap tasks"
  task(:bootstrap) do
    Rake::Task["kp:bootstrap:create_system_roles"].invoke
    Rake::Task["kp:bootstrap:create_admin_account"].invoke
    Rake::Task["kp:bootstrap:create_school_types"].invoke
  end

  namespace :bootstrap do

    # Creates all system roles required in the application
    desc "Create system roles if they do not exist"
    task(create_system_roles: :environment) do
      [:admin, :booker, :culture_worker, :host, :coordinator].each do |role|
        unless Role.find_by_symbol role
          r = Role.new
          r.name = role.to_s

          puts "Role: #{role.to_s}"
          r.save!
        end
      end
    end

    # Creates an administrator account in the application
    desc "Create admin account if it does not exist"
    task(create_admin_account: :environment) do
      unless User.where(username: "admin").exists?
        u = User.new
        u.username = "admin"
        u.password = "admin"
        u.name = "Admin"
        u.email = "admin@admin.com"
        u.cellphone = "0"

        puts "User: #{u.username}"
        u.save(validate: false)

        u.roles << Role.find_by_symbol(:admin)
      end
    end

    # Creates the school types required for the application
    desc "Create school types if they do not exist"
    task(create_school_types: :environment) do
      %w(Förskola Grundskola).each do |type|
        unless SchoolType.where(name: type).exists?
          school_type = SchoolType.new
          school_type.name = type

          puts "School type: #{type}"
          school_type.save!
        end
      end
    end
  end
end

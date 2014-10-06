# config valid only for Capistrano 3.2.1
lock "3.2.1"

set :application, "kulturproceduren"
set :repo_url, "https://github.com/malmostad/kulturproceduren.git"

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "$HOME/app/"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/app_config.confidential.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads public/images/model}

# Default value for default_env is {}

# Default value for keep_releases is 5
set :keep_releases, 10

set :rbenv_type, :user
set :rbenv_ruby, "2.1.0"
set :default_env, proc { {
  "LD_LIBRARY_PATH" => "$HOME/.rbenv/versions/#{fetch(:rbenv_ruby)}/lib:$LD_LIBRARY_PATH",
  "RAILS_RELATIVE_URL_ROOT" => fetch(:relative_url_root)
} }
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails}
set :rbenv_roles, :all # default value

namespace :deploy do

  desc "Restart application"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join("tmp/restart.txt")
    end
  end

  after :publishing, :restart

  desc "Start application"
  task :start do
    on roles(:app) do
      within release_path do
        execute :bundle, "exec passenger start -d -p #{fetch(:passenger_port)} -e #{fetch(:rails_env) || fetch(:stage)}"
      end
    end
  end
  desc "Stop application"
  task :stop do
    on roles(:app) do
      within release_path do
        execute :bundle, "exec passenger stop -p #{fetch(:passenger_port)}"
      end
    end
  end
end

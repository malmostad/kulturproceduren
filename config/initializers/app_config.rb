# Creates an application config hash on a global level using settings
# in the given YAML file.
APP_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/app_config.yml")[RAILS_ENV]

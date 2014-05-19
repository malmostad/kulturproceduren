# PaperTrail configuration
PaperTrail.config.version_limit = 5 # 5 versions + 1 create

module PaperTrail
  class Version < ActiveRecord::Base
    attr_accessible :extra_data
    serialize :extra_data, PaperTrail.serializer
  end
end

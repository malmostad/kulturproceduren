# An category, currently used only for categorizing events.
#
# Event categories are grouped by category groups, which affects how
# they are displayed in the user interface.
class Category < ActiveRecord::Base
  belongs_to :category_group
  has_and_belongs_to_many :events

  validates_presence_of :name,
    :message => "Namnet får inte vara tomt"
end

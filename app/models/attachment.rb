# Model representing an attachment, currently used for
# documents attached to events
class Attachment < ActiveRecord::Base
  belongs_to :event

  attr_accessible :description,
    :filename,
    :content_type,
    :event_id, :event

  validates_presence_of :description,
    message: "Beskrivningen får inte vara tom"
  validates_presence_of :filename,
    message: "Filnamnet får inte vara tomt"
  validates_presence_of :content_type,
    message: "Content type får inte vara tom"
end

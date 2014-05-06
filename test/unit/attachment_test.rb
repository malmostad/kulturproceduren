require 'test_helper'

class AttachmentTest < ActiveSupport::TestCase
  test "validations" do
    attachment = build(:attachment, description: "")
    assert !attachment.valid?
    assert attachment.errors.include?(:description)
    attachment = build(:attachment, filename: "")
    assert !attachment.valid?
    assert attachment.errors.include?(:filename)
    attachment = build(:attachment, content_type: "")
    assert !attachment.valid?
    assert attachment.errors.include?(:content_type)
  end
end

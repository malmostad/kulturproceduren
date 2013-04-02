require 'test_helper'

class AttachmentTest < ActiveSupport::TestCase
  test "validations" do
    attachment = build(:attachment, :description => "")
    assert !attachment.valid?
    assert_not_nil attachment.errors.on(:description)
    attachment = build(:attachment, :filename => "")
    assert !attachment.valid?
    assert_not_nil attachment.errors.on(:filename)
    attachment = build(:attachment, :content_type => "")
    assert !attachment.valid?
    assert_not_nil attachment.errors.on(:content_type)
  end
end

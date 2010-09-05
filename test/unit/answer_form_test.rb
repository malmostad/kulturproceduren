require 'test_helper'

class AnswerFormTest < ActiveSupport::TestCase
  test "generated id" do
    a = AnswerForm.new
    assert_nil a.id
    a.save
    assert_match /^[A-Za-z0-9]{45}$/, a.id
  end

  test "find overdue" do
    target_date = Date.today - 2
    as = AnswerForm.find_overdue(target_date)

    assert !as.empty?

    as.each do |a|
      assert !a.completed
      assert target_date == a.occasion.date
    end
  end
end

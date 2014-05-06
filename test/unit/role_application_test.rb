# -*- encoding : utf-8 -*-
require 'test_helper'

class RoleApplicationTest < ActiveSupport::TestCase
  test "validations" do
    booker         = create(:role, name: "booker")
    culture_worker = create(:role, name: "culture_worker")

    assert build(:role_application, message: "").valid?
    role_application = build(:role_application, role: booker, message: "")
    assert !role_application.valid?
    assert role_application.errors.include?(:message)

    assert build(:role_application, culture_provider: nil, new_culture_provider_name: "").valid?
    assert build(:role_application, role: culture_worker, culture_provider: create(:culture_provider), new_culture_provider_name: "").valid?
    assert build(:role_application, role: culture_worker, culture_provider: nil, new_culture_provider_name: "test").valid?
    role_application = build(:role_application, role: culture_worker, culture_provider: nil, new_culture_provider_name: "")
    assert !role_application.valid?
    assert role_application.errors.include?(:culture_provider_id)
  end
end

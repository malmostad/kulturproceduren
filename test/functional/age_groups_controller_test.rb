# -*- encoding : utf-8 -*-
require 'test_helper'

class AgeGroupsControllerTest < ActionController::TestCase
  def setup
    # Stub ActionController filters
    @controller.expects(:authenticate).at_least_once.returns(true)
    @controller.expects(:require_admin).at_least_once.returns(true)
  end

  test "edit" do
    age_group = create(:age_group)
    get :edit, :id => age_group.id
    assert_equal age_group,       assigns(:age_group)
    assert_equal age_group.group, assigns(:group)
    assert_template "groups/show"
  end
  test "create" do
    group = create(:group)
    assert !AgeGroup.exists?

    # Valid
    post :create, :age_group => { :age => 10, :quantity => 25, :group_id => group.id }
    assert_equal "Åldersgruppen skapades.", flash[:notice]
    assert_redirected_to group
    age_group = AgeGroup.first
    assert_equal 10,    age_group.age
    assert_equal 25,    age_group.quantity
    assert_equal group, age_group.group

    # Invalid
    post :create, :age_group => { :group_id => group.id }
    assert !assigns(:age_group).valid?
    assert_equal group, assigns(:group)
    assert_template "groups/show"
  end
  test "update" do
    age_group = create(:age_group)

    # Valid
    put :update, :id => age_group.id, :age_group => { :age => age_group.age + 1, :quantity => age_group.quantity + 1 }
    assert_equal "Åldersgruppen uppdaterades.", flash[:notice]
    assert_redirected_to age_group.group
    updated = AgeGroup.find(age_group.id)
    assert_equal age_group.age + 1,      updated.age
    assert_equal age_group.quantity + 1, updated.quantity

    # Invalid
    put :update, :id => age_group.id, :age_group => { :age => "foo" }
    assert !assigns(:age_group).valid?
    assert_equal age_group.group, assigns(:group)
    assert_template "groups/show"
  end
  test "destroy" do
    age_group = create(:age_group)
    delete :destroy, :id => age_group.id
    assert_redirected_to age_group.group
    assert !AgeGroup.exists?(age_group.id)
  end
end

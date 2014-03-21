# -*- encoding : utf-8 -*-
require 'test_helper'

class CategoryGroupsControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
    @controller.expects(:require_admin).at_least_once.returns(true)

    @user = create(:user, :roles => [roles(:admin)])
    session[:current_user_id] = @user.id

    @category_groups = create_list(:category_group, 2)
  end

  test "index" do
    get :index
    assert_response :success
    assert_equal    CategoryGroup.all, assigns(:category_groups)
    assert          assigns(:category_group).new_record?
  end

  test "edit" do
    get :edit, :id => @category_groups.first.id
    assert_response :success
    assert_template "category_groups/index"
    assert_equal    CategoryGroup.all,      assigns(:category_groups)
    assert_equal    @category_groups.first, assigns(:category_group)
  end

  test "create" do
    # Invalid
    post :create, :category_group => { :name => "" }
    assert_response :success
    assert_template "category_groups/index"
    assert          !assigns(:category_group).valid?

    # Valid
    post :create, :category_group => { :name => "zomg" }
    assert_redirected_to :action => "index"
    assert_equal         "Kategorigruppen skapades.", flash[:notice]

    category_group = CategoryGroup.find(assigns(:category_group).id)
    assert_equal "zomg", category_group.name
  end

  test "update" do
    category_group = @category_groups.second
    # Invalid
    put :update, :id => category_group.id, :category_group => { :name => "" }
    assert_response :success
    assert_template "category_groups/index"
    assert_equal    category_group, assigns(:category_group)
    assert          !assigns(:category_group).valid?

    # Valid
    put :update, :id => category_group.id, :category_group => { :name => "zomg" }
    assert_redirected_to :action => "index"
    assert_equal         "Kategorigruppen uppdaterades.", flash[:notice]

    category_group.reload
    assert_equal "zomg", category_group.name
  end

  test "destroy" do
    category_group = @category_groups.second

    delete :destroy, :id => category_group.id
    assert_redirected_to :action => "index"
    assert_equal         "Kategorigruppen togs bort.", flash[:notice]
    assert_nil           CategoryGroup.where(:id => category_group.id).first
  end
end

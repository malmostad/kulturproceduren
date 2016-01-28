require_relative '../test_helper'

class CategoriesControllerTest < ActionController::TestCase
  def setup
    @controller.expects(:authenticate).at_least_once.returns(true)
    @controller.expects(:require_admin).at_least_once.returns(true)

    @user = create(:user, roles: [roles(:admin)])
    session[:current_user_id] = @user.id

    @categories = create_list(:category, 2)
  end

  test "index" do
    get :index
    assert_equal Category.includes(:category_group).order("category_groups.name asc, categories.name asc").to_a, assigns(:categories)
    assert_equal CategoryGroup.all, assigns(:category_groups)
    assert       assigns(:category).new_record?
    assert_nil   assigns(:category).category_group_id

    session[:selected_category_group] = @categories.first.category_group_id
    get :index
    assert_equal @categories.first.category_group_id, assigns(:category).category_group_id
  end

  test "edit" do
    get :edit, id: @categories.second.id

    assert_template "categories/index"

    assert_equal Category.all,       assigns(:categories)
    assert_equal CategoryGroup.all,  assigns(:category_groups)
    assert_equal @categories.second, assigns(:category)
  end

  test "create, invalid" do
    post :create, category: { name: "" }
    assert_response :success
    assert_template "categories/index"
    assert          assigns(:category).new_record?
    assert          !assigns(:category).valid?
    assert_equal    Category.all,      assigns(:categories)
    assert_equal    CategoryGroup.all, assigns(:category_groups)
  end
  test "create, valid" do
    post :create, category: { name: "zomg", category_group_id: @categories.second.category_group_id }
    assert_redirected_to action: "index"
    assert_equal         "Kategorin skapades.", flash[:notice]
    assert_nil           assigns(:categories)
    assert_nil           assigns(:category_groups)

    category = Category.find(assigns(:category).id)

    assert_equal "zomg",                            category.name
    assert_equal @categories.second.category_group, category.category_group
  end

  test "update, invalid" do
    put :update, id: @categories.second.id, category: { name: "" }
    assert_response :success
    assert_template "categories/index"
    assert_equal    @categories.second, assigns(:category)
    assert          !assigns(:category).valid?
    assert_equal    Category.all,       assigns(:categories)
    assert_equal    CategoryGroup.all,  assigns(:category_groups)
  end
  test "update, valid" do
    put :update, id: @categories.second.id, category: { name: "zomg", category_group_id: @categories.first.category_group_id }
    assert_redirected_to action: "index"
    assert_equal         "Kategorin uppdaterades.", flash[:notice]
    assert_nil           assigns(:categories)
    assert_nil           assigns(:category_groups)

    category = @categories.second
    category.reload

    assert_equal "zomg",                           category.name
    assert_equal @categories.first.category_group, category.category_group(true)
  end

  test "destroy" do
    category = @categories.second

    delete :destroy, id: category.id
    assert_redirected_to action: "index"
    assert_equal "Kategorin togs bort.", flash[:notice]
    assert_nil Category.where( id: category.id ).first
  end
end

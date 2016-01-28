require_relative '../../test_helper'

class ApplicationHelperTest < ActionView::TestCase
  include ERB::Util

  def params
    @dummy_params
  end

  test "active by controller" do
    @dummy_params = { controller: "test", action: "test" }
    assert_equal " active ", active_by_controller("test", "test2")
    assert_equal " active ", active_by_controller("test2", "test")
    assert_nil active_by_controller("test2")
  end

  test "active by action" do
    @dummy_params = { controller: "test", action: "test" }
    assert_equal " active ", active_by_action("test", "test", "test1")
    assert_equal " active ", active_by_action("test", "test1", "test")
    assert_nil active_by_action("test1", "test")
    assert_nil active_by_action("test", "test1", "test2")
  end

  test "disabled if" do
    assert_equal ' disabled="disabled" ', disabled_if(1 == 1)
    assert_nil disabled_if(1 == 2)
  end

  test "empty" do
    assert empty?(nil)
    assert empty?("")
    assert empty?("\t \n")
    assert !empty?(" abc")
  end

  test "qualified url" do
    assert_equal "http://www.malmo.se", qualified_url("http://www.malmo.se")
    assert_equal "http://www.malmo.se", qualified_url("www.malmo.se")
  end

  test "paragraphize" do
    assert_equal '<p class="test">abc<br/>d&lt;ef</p><p class="test">ghi</p>',
      paragraphize("abc\nd<ef\n\nghi", 'class="test"')
  end

  test "linebreakize" do
    assert_equal 'abc<br/>d&lt;ef<br/>ghi',
      linebreakize("abc\nd<ef\nghi")
  end

  test "show description" do
    assert_equal "", show_description(nil)
    assert_equal paragraphize("abc\ndef\n\nghi"), show_description("abc\ndef\n\nghi")
    self.expects(:sanitize).with(
      "<p>foo</p>",
      tags: %w(a b strong i em span p ul ol li h1 h2 h3 h4 h5 h6 blockquote),
      attributes: %w(href target title style)
    ).returns("ok_value")
    assert_equal "ok_value", show_description("<p>foo</p>")
  end

  def link_to_unless(condition, title, url)
    @link_to_result = {
      condition: condition,
      title: title,
      url: url
    }
  end

  test "sort link" do
    @dummy_params = {
      controller: "test",
      action: "test",
      d: "up", c: "testcolumn"
    }
    sort_link("link title", "testcolumn")
    assert_equal "link title", @link_to_result[:title]
    assert_equal "testcolumn", @link_to_result[:url][:c]
    assert_equal "down", @link_to_result[:url][:d]

    sort_link("link title", "testcolumn2")
    assert_equal "link title", @link_to_result[:title]
    assert_equal "testcolumn2", @link_to_result[:url][:c]
    assert_equal "up", @link_to_result[:url][:d]
  end

  test "uploaded image tag" do
    img = Image.new do |i|
      i.description = "test<image"
      i.filename = "testimage.jpg"
      i.width = 300
      i.height = 400
      i.thumb_width = 30
      i.thumb_height = 40
    end

    assert_equal '<img alt="test&lt;image" height="400" src="/images/model/testimage.jpg" title="test&lt;image" width="300" />',
      uploaded_image_tag(img)
    assert_equal '<img alt="test&lt;image" height="40" src="/images/model/testimage.thumb.jpg" title="test&lt;image" width="30" />',
      uploaded_image_tag(img, true)
  end

  test "conditional_cache" do
    self.expects(:cache).returns("cached")
    assert_equal "cached", conditional_cache(true)
    self.expects(:capture).returns("capture")
    assert_equal "capture", conditional_cache(false)
  end

  test "to term" do
    assert_equal "vt2009", to_term(Date.new(2009, 1, 1))
    assert_equal "vt2009", to_term(Date.new(2009, 3, 1))
    assert_equal "vt2009", to_term(Date.new(2009, 6, 30))
    assert_equal "ht2009", to_term(Date.new(2009, 7, 1))
    assert_equal "ht2009", to_term(Date.new(2009, 9, 1))
    assert_equal "ht2009", to_term(Date.new(2009, 12, 31))
    assert_equal "vt2010", to_term(Date.new(2010, 1, 1))
  end

  test "group_selection_form, no arguments, no state" do
    request = stub(
      path_parameters: { controller: "booking" },
      query_parameters: { action: "new" }
    )
    self.stubs(:request).returns(request)

    group_selection_form()

    assert_select "form", 2
    assert_select "#group-selection-group option", 0
    assert_select "#group-selection-group[disabled]", 1
    assert_select "[name=return_to][value=/booking/new]", 2
    assert_select "[data-search-path=/schools/search]", 1
    assert_select "[name=occasion_id]", 0
  end

  test "group_selection_form, return_to, no state" do
    group_selection_form(return_to: "/foo/bar")

    assert_select "form", 2
    assert_select "#group-selection-group option", 0
    assert_select "#group-selection-group[disabled]", 1
    assert_select "[name=return_to][value=/foo/bar]", 2
    assert_select "[name=occasion_id]", 0
  end

  test "group_selection_form, school_search_path, no state" do
    group_selection_form(return_to: "/foo", school_search_path: "/foo/bar")
    assert_select "[data-search-path=/foo/bar]", 1
  end
  test "group_selection_form, notification_request_hint, no state" do
    occasion = create(:occasion)
    group_selection_form(return_to: "/foo", notification_request_hint: true, occasion: occasion)
    assert_select "p.help-block", 1
    assert_select "p.help-block a[href=/events/#{occasion.event_id}/notification_requests/new]"
  end
  test "group_selection_form, select_button, no state" do
    occasion = create(:occasion)
    group_selection_form(return_to: "/foo", select_button: "select_button", occasion: occasion)
    assert_select "button.select-group", 1
  end

  test "group_selection_form, return_to, school selected" do
    group = create(:group)
    session[:group_selection] = {
      school_id: group.school.id,
      school_name: group.school.name
    }

    group_selection_form(return_to: "/")

    assert_select "form", 2
    assert_select "#group-selection-group option", 1+1 # Blank entry and one group
    assert_select "#group-selection-group[disabled]", 0
    assert_select "#group-selection-group option[selected]", 0
    assert_select "[name=return_to][value=/]", 2
    assert_select "[name=occasion_id]", 0
  end

  test "group_selection_form, return_to, group selected" do
    group = create(:group)
    session[:group_selection] = {
      school_id: group.school.id,
      school_name: group.school.name,
      group_id: group.id
    }

    group_selection_form(return_to: "/")

    assert_select "form", 2
    assert_select "#group-selection-group option", 1+1 # Blank entry and one group
    assert_select "#group-selection-group[disabled]", 0
    assert_select "#group-selection-group option[selected]", { count: 1, text: group.name }
    assert_select "[name=return_to][value=/]", 2
    assert_select "[name=occasion_id]", 0
  end

  test "group_selection_form, occasion allotted to group, group selected" do
    group1 = create(:group)
    group2 = create(:group, school: group1.school)

    occasion = create(:occasion, seats: 2)
    event = occasion.event

    create_list(:ticket, 1, group: group1, district: group1.school.district, event: event, state: :unbooked)

    session[:group_selection] = {
      school_id: group1.school.id,
      school_name: group1.school.name,
      group_id: group1.id
    }

    group_selection_form(occasion: occasion, return_to: "/")

    assert_select "form", 2
    assert_select "#group-selection-group option", 1+1 # Blank entry and one group
    assert_select "#group-selection-group[disabled]", 0
    assert_select "#group-selection-group option[selected]", { count: 1, text: "#{group1.name} (1 platser)" }
    assert_select "[name=return_to][value=/]", 2
    assert_select "[name=occasion_id]", 2
  end
end

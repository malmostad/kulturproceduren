require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  def params
    @dummy_params
  end

  test "active by controller" do
    @dummy_params = { :controller => "test", :action => "test" }
    assert_equal " active ", active_by_controller("test", "test2")
    assert_equal " active ", active_by_controller("test2", "test")
    assert_nil active_by_controller("test2")
  end

  test "active by action" do
    @dummy_params = { :controller => "test", :action => "test" }
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
    assert_equal '<p class="test">abc<br/>def</p><p class="test">ghi</p>',
      paragraphize("abc\ndef\n\nghi", 'class="test"')
  end

  test "linebreakize" do
    assert_equal 'abc<br/>def<br/>ghi',
      linebreakize("abc\ndef\nghi")
  end

  def link_to_unless(condition, title, options)
    @link_to_result = {
      :condition => condition,
      :title => title,
      :options => options
    }
  end

  test "sort link" do
    @dummy_params = {
      :controller => "test",
      :action => "test",
      :d => "up", :c => "testcolumn"
    }
    sort_link("link title", "testcolumn")
    assert_equal "link title", @link_to_result[:title]
    assert_equal "testcolumn", @link_to_result[:options][:overwrite_params][:c]
    assert_equal "down", @link_to_result[:options][:overwrite_params][:d]

    sort_link("link title", "testcolumn2")
    assert_equal "link title", @link_to_result[:title]
    assert_equal "testcolumn2", @link_to_result[:options][:overwrite_params][:c]
    assert_equal "up", @link_to_result[:options][:overwrite_params][:d]
  end

  test "uploaded image tag" do
    img = Image.new do |i|
      i.name = "testimage"
      i.filename = "testimage.jpg"
      i.width = 300
      i.height = 400
      i.thumb_width = 30
      i.thumb_height = 40
    end

    assert_equal '<img alt="testimage" height="400" src="/images/model/testimage.jpg" width="300" />',
      uploaded_image_tag(img)
    assert_equal '<img alt="testimage" height="40" src="/images/model/testimage.thumb.jpg" width="30" />',
      uploaded_image_tag(img, true)
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

end

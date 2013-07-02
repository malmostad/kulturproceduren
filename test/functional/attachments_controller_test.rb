require 'test_helper'

class AttachmentsControllerTest < ActionController::TestCase
  def setup
    # Stub ActionController filters
    @controller.expects(:authenticate).at_least_once.returns(true)

    @event = create(:event)
    @user  = create(:user, :roles => [roles(:culture_worker)], :culture_providers => [@event.culture_provider])
    session[:current_user_id] = @user.id
  end

  test "event loading" do
    get :index, :event_id => 0
    assert_redirected_to root_url()
    assert_equal "Du måste ange ett giltigt evenemang.", flash[:error]
    post :create, :event_id => 0
    assert_redirected_to root_url()
    assert_equal "Du måste ange ett giltigt evenemang.", flash[:error]
    delete :destroy, :event_id => 0
    assert_redirected_to root_url()
    assert_equal "Du måste ange ett giltigt evenemang.", flash[:error]
  end
  test "require culture worker" do
    @user.culture_providers.clear
    get :index, :event_id => @event.id
    assert_redirected_to @event
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
    post :create, :event_id => @event.id
    assert_redirected_to @event
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
    delete :destroy, :event_id => @event.id
    assert_redirected_to @event
    assert_equal "Du har inte behörighet att komma åt sidan.", flash[:error]
  end

  test "index" do
    get :index, :event_id => @event.id
    assert_response :success
    assert assigns(:attachment).new_record?
    assert @event, assigns(:attachment).event
  end

  test "show" do
    APP_CONFIG.replace(:upload_attachment => { :path => "../tmp" })
    attachment = create(:attachment, :content_type => "text/plain", :filename => "foo.txt")

    @controller.expects(:render)
    @controller.expects(:send_file).with(
      Rails.root.join("tmp", "#{attachment.id}.txt"),
      :type => "text/plain",
      :filename => "foo.txt"
    )

    get :show, :id => attachment.id
    assert_equal attachment, assigns(:attachment)
  end

  test "create" do
    # Missing data
    post :create, :event_id => @event.id
    assert_redirected_to event_attachments_url(@event)
    assert_equal "Du måste välja en fil att ladda upp.", flash[:warning]
    post :create, :event_id => @event.id, :upload => {}
    assert_redirected_to event_attachments_url(@event)
    assert_equal "Du måste välja en fil att ladda upp.", flash[:warning]

    upload_file = Rack::Test::UploadedFile.new("#{Rails.root}/Rakefile", "text/plain")

    # Proper data, unable to save
    post :create,
      :event_id => @event.id,
      :attachment => {}, # no description => invalid
      :upload => { :document => upload_file }
    assert_template "attachments/index"
    assert assigns(:attachment).new_record?

    # Proper data, saving success
    APP_CONFIG.replace(:upload_attachment => { :path => "../tmp" })

    post :create,
      :event_id => @event.id,
      :attachment => { :description => "foo" },
      :upload => { :document => upload_file }
    assert_redirected_to event_attachments_url(@event)
    assert_equal "Filen laddades upp.", flash[:notice]

    assert_equal "foo",        assigns(:attachment).description
    assert_equal "Rakefile",   assigns(:attachment).filename
    assert_equal "text/plain", assigns(:attachment).content_type
    assert_equal @event,       assigns(:attachment).event

    outfile = Rails.root.join("tmp", "#{assigns(:attachment).id}")
    assert File.exists?(outfile)

    File.delete(outfile)
  end

  test "destroy" do
    APP_CONFIG.replace(:upload_attachment => { :path => "../tmp" })
    attachment = create(:attachment, :content_type => "text/plain", :filename => "foo.txt", :event => @event)

    File.expects(:delete).with(Rails.root.join("tmp", "#{attachment.id}.txt"))

    delete :destroy, :id => attachment.id, :event_id => @event.id

    assert_redirected_to event_attachments_url(@event)
    assert_equal         "Filen togs bort.", flash[:notice]
    assert               !Attachment.exists?(attachment.id)
  end
end

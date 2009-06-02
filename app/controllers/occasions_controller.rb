class OccasionsController < ApplicationController

  before_filter :authenticate, :only => [ :index ]
  layout "standard"


  def index
    @today = Date.today

    @visible_events = Event.find( :all, :conditions => "show_date < '#{@today.to_s}'")
    @visible_occasions = []

    @visible_events.each do |e|
      o = Occasion.find(:all, :conditions => "event_id = #{e.id}")
      o.each do |oo|
        @visible_occasions.push(oo)
      end
    end

    @user = current_user
    @user_events = Event.visible_events_by_userid(@user.id)
    @user_events_hash_by_id = {}

    @user_events.each do |e|
      @user_events_hash_by_id[e.id] = e
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @occasions }
    end
  end

  def show
    @occasion = Occasion.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @occasion }
    end
  end

  def new
    @occasion = Occasion.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @occasion }
    end
  end

  def edit
    @occasion = Occasion.find(params[:id])
    @event = @occasion.event

    render :template => "events/show"
  end

  def create
    @occasion = Occasion.new(params[:occasion])

    if @occasion.save
      flash[:notice] = 'Föreställningen skapades.'
      redirect_to(@occasion.event)
    else
      @event = @occasion.event
      render :template => "events/show"
    end
  end

  def update
    @occasion = Occasion.find(params[:id])

    if @occasion.update_attributes(params[:occasion])
      flash[:notice] = 'Föreställningen uppdaterades.'
      redirect_to(@occasion.event)
    else
      @event = @occasion.event
      render :template => "events/show"
    end
  end

  def destroy
    @occasion = Occasion.find(params[:id])
    @occasion.destroy

    redirect_to(occasions_url)
  end
end

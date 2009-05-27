class QuestionairesController < ApplicationController
  layout "standard"
  before_filter :authenticate
  require "pp"
  # GET /questionaires
  # GET /questionaires.xml
  def index
    @questionaires = Questionaire.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @questionaires }
    end
  end

  # GET /questionaires/1
  # GET /questionaires/1.xml
  def show
    @user = User.find_by_id(session[:current_user_id])
    @questionaire = Questionaire.find(params[:id])
    @all_q = Question.find(:all)
    if @user.roles.include?(Role.find_by_name("Administratör"))
      render :admin_view
    end
  end

  # GET /questionaires/new
  # GET /questionaires/new.xml
  def new
    if ! Event.all.collect { |e| e.questionaire.nil? }.include?(true)
      flash[:error] = "Alla evenamng har redan enkäter!"
      redirect_to :controller => "questionaires" , :action => "index"
      return
    end
    @questionaire = Questionaire.new
    @user = User.find_by_id(session[:current_user_id])
    @all_q = Question.find(:all)
    if @user.roles.include?(Role.find_by_name("Administratör"))
      render :new
    else
      flash[:error] = "RED ALERT - UNAUTHORIZED ACCESS - ALL HANDS TO BATTLE STATIONS"
      redirect_to "/"
    end
  end

  # GET /questionaires/1/edit
  def edit
    @questionaire = Questionaire.find(params[:id])
    @user = User.find_by_id(session[:current_user_id])
    @all_q = Question.find(:all)
    if @user.roles.include?(Role.find_by_name("Administratör"))
      render :admin_view
    else
      flash[:error] = "RED ALERT - UNAUTHORIZED ACCESS - ALL HANDS TO BATTLE STATIONS"
      redirect_to "/"
    end
  end

  # POST /questionaires
  # POST /questionaires.xml
  def create
    @questionaire = Questionaire.new(params[:questionaire])
    @questionaire.question_ids = Question.find(:all, :conditions => "template is true").collect { |q| q.id }
    
    if @questionaire.save
      flash[:notice] = 'Questionaire was successfully created.'
      redirect_to @questionaire 
    else
      render :action => "new" 
    end
  end

  # PUT /questionaires/1
  # PUT /questionaires/1.xml
  def update
    @questionaire = Questionaire.find(params[:id])
    if @questionaire.update_attributes(params[:questionaire])
      flash[:notice] = 'Questionaire was successfully updated.'
      redirect_to(@questionaire) 
    else
      render :action => "edit" 
    end
  end

  # DELETE /questionaires/1
  # DELETE /questionaires/1.xml
  def destroy
    @questionaire = Questionaire.find(params[:id])
    @questionaire.destroy

    respond_to do |format|
      format.html { redirect_to(questionaires_url) }
      format.xml  { head :ok }
    end
  end
end

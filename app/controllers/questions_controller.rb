class QuestionsController < ApplicationController
  layout "standard"
  require "pp"
  
  # GET /questions
  # GET /questions.xml
  def index
    @questions = Question.all
    @user = User.find_by_id(session[:current_user_id])

  end

  # GET /questions/1
  # GET /questions/1.xml
  def show
    @question = Question.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @question }
    end
  end

  # GET /questions/new
  # GET /questions/new.xml
  def new
    @question = Question.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @question }
    end
  end

  # GET /questions/1/edit
  def edit
    @question = Question.find(params[:id])
    @questionaire = Questionaire.find_by_id(params[:questionaire_id])
    @user = User.find_by_id(session[:current_user_id])
    @all_q = Question.find(:all)
    if @user.roles.include?(Role.find_by_name("Administratör"))
      render :template => "questionaires/admin_view"
    end
    
  end

  # POST /questions
  # POST /questions.xml
  def create
    @question = Question.new(params[:question])
    res = @question.save
    @questionaire = Questionaire.find_by_id(params[:questionaire_id])
    a = @questionaire.question_ids
    a.push(@question.id)
    @questionaire.question_ids = a
    if not @questionaire.save
      flash[:error] = "Kunde inte uppdatera enkäten med nya frågor"
    end
    if res
        flash[:notice] = 'Ny fråga skapad'
        redirect_to(@questionaire)
      else
        flash[:error] += " Kunde inte skapa fråga!"
        redirect_to :controller => "questionaire" , :action => "index"
    end
  end

  # PUT /questions/1
  # PUT /questions/1.xml
  def update
    @question = Question.find(params[:id])
    if @question.update_attributes(params[:question])
      flash[:notice] = 'Question was successfully updated.'
      redirect_to(Questionaire.find_by_id(params[:questionaire_id]))
    else
      flash[:error] = "Frågan kunde inte uppdateras"
      redirect_to(Questionaire.find_by_id(params[:questionaire_id]))
    end
  end

  # DELETE /questions/1
  # DELETE /questions/1.xml
  def destroy
    @question = Question.find(params[:question_id])
    @question.destroy
    @questionaire = Questionaire.find_by_id(params[:questionaire_id])

    redirect_to @questionaire
    
    
  end
end

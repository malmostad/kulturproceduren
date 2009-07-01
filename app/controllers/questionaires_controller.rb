class QuestionairesController < ApplicationController

  layout "admin"
  
  before_filter :authenticate
  before_filter :require_admin
  
  def index
    @questionaires = Questionaire.paginate :page => params[:page],
      :include => :event,
      :order => sort_order("events.name")
  end

  def show
    @questionaire = Questionaire.find params[:id], :include => :event
    @question = Question.new do |q|
      q.template = false
      q.qtype = "QuestionMark"
    end

    @template_questions = Question.find :all,
      :conditions => { :template => true },
      :order => "question ASC"
  end

  def add_template_question
    questionaire = Questionaire.find params[:id]
    question = Question.find params[:question_id]

    begin
      questionaire.questions << question
    rescue; end

    redirect_to questionaire
  end

  def remove_template_question
    questionaire = Questionaire.find params[:id]
    question = Question.find params[:question_id]

    begin
      questionaire.questions.delete question
    rescue; end

    redirect_to questionaire
  end

  def new
    @events = Event.without_questionaires.find :all, :order => "name"
    @questionaire = Questionaire.new
  end

  def edit
    @questionaire = Questionaire.find params[:id], :include => :event
    render :action => "new"
  end

  def create
    @questionaire = Questionaire.new(params[:questionaire])
    @questionaire.questions = Question.find(:all , :conditions => { :template => true })
    if @questionaire.save
      flash[:notice] = 'Enkäten skapades.'
      redirect_to @questionaire 
    else
      flash.now[:error] = 'Fel uppstod när enkäten skulle skapas.'
      render :action => "new" 
    end
  end

  def update
    @questionaire = Questionaire.find(params[:id])
    
    if @questionaire.update_attributes(params[:questionaire])
      flash[:notice] = 'Enkäten uppdaterades.'
      redirect_to(@questionaire) 
    else
      flash.now[:error] = 'Fel uppstod när enkäten skulle uppdateras.'
      render :action => "new"
    end
  end

  def destroy
    @questionaire = Questionaire.find(params[:id])
    @questionaire.destroy
    
    redirect_to(questionaires_url)
  end


  protected

  def sort_column_from_param(p)
    return "events.name"
  end
end

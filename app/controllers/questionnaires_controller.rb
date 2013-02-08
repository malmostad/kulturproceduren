# Controller for managing quiestionnaires.
class QuestionnairesController < ApplicationController

  layout "admin"
  
  before_filter :authenticate
  before_filter :require_admin
  
  # Displays a list of all questionnaires in the system.
  def index
    @questionnaires = Questionnaire.for_event.paginate :page => params[:page],
      :include => :event,
      :order => sort_order("events.name")
  end

  # Displays details about a questionnaire, as well as a form
  # for adding questions to the questionnaire.
  def show
    @questionnaire = Questionnaire.find params[:id], :include => :event
    @question = Question.new do |q|
      q.template = false
      q.qtype = "QuestionMark"
    end

    @template_questions = Question.find(
      :all,
      :conditions => { :template => true },
      :order => "question ASC"
    ) if @questionnaire.for_event?
  end

  # Displays details about the unbooking questionnaire
  def unbooking
    redirect_to Questionnaire.find_unbooking
  end

  def add_template_question
    questionnaire = Questionnaire.find params[:id]
    question = Question.find params[:question_id]

    begin
      questionnaire.questions << question
    rescue; end

    redirect_to questionnaire
  end

  def remove_template_question
    questionnaire = Questionnaire.find params[:id]
    question = Question.find params[:question_id]

    begin
      questionnaire.questions.delete question
    rescue; end

    redirect_to questionnaire
  end

  def new
    @events = Event.without_questionnaires.find :all, :order => "name"
    @questionnaire = Questionnaire.new
  end

  def edit
    @questionnaire = Questionnaire.find params[:id], :include => :event
    render :action => "new"
  end

  def create
    @questionnaire = Questionnaire.new(params[:questionnaire])
    @questionnaire.target_cd = Questionnaire.targets.for_event
    @questionnaire.questions = Question.find(:all , :conditions => { :template => true })
    if @questionnaire.save
      flash[:notice] = 'Enkäten skapades.'
      redirect_to @questionnaire 
    else
      render :action => "new" 
    end
  end

  def update
    @questionnaire = Questionnaire.find(params[:id])
    
    if @questionnaire.update_attributes(params[:questionnaire])
      flash[:notice] = 'Enkäten uppdaterades.'
      redirect_to(@questionnaire) 
    else
      render :action => "new"
    end
  end

  def destroy
    @questionnaire = Questionnaire.find(params[:id])
    @questionnaire.destroy
    
    redirect_to(questionnaires_url)
  end


  protected

  # Sort the questionnaires by the name of the events they belong to.
  def sort_column_from_param(p)
    return "events.name"
  end
end

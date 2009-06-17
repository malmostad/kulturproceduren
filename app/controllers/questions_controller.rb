class QuestionsController < ApplicationController
  layout "standard"
  require "pp"
  
  def index
    @questions = Question.all
    @user = current_user

  end

  def show
    @question = Question.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @question }
    end
  end

  def new
    @question = Question.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @question }
    end
  end

  def edit
    @question = Question.find(params[:id])
    @questionaire = Questionaire.find(params[:questionaire_id])
    @user = current_user
    @all_q = Question.all
    puts "in questions controller"
    pp @all_q
    if current_user.has_role?(:admin)
      render :template => "questionaires/admin_view"
    end
    
  end

  def create
    @question = Question.new
    if params[:"kp-qtype"] == "QuestionMchoice"
      @question.choice_csv = params[:mchoice]
    end
    @question.qtype = params[:"kp-qtype"]
    @question.question = params[:question]
    @question.template = params[:template]
    res = @question.save
    
    @questionaire = Questionaire.find(params[:questionaire_id])
    a = @questionaire.question_ids
    a.push(@question.id)
    @questionaire.question_ids = a
    puts "Skapade fråga med id = #{@question.id}"
    pp @questionaire
    puts "Frågor på questionaire ..."
    pp @questionaire.question_ids

    if !@questionaire.save
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

  def update
    @question = Question.find(params[:question_id])
    @question.question = params[:question]
    @question.template = params[:template]
    @question.choice_csv = params[:mchoice]
    @question.qtype = params[:"kp-qtype"]
    
    if @question.save
      flash[:notice] = 'Question was successfully updated.'
    else
      flash[:error] = "Frågan kunde inte uppdateras"
    end
    
    redirect_to(Questionaire.find(params[:questionaire_id]))
  end

  def destroy
    @question = Question.find(params[:question_id])
    @question.destroy
    @questionaire = Questionaire.find(params[:questionaire_id])

    redirect_to @questionaire
  end
end

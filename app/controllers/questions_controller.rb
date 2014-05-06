# -*- encoding : utf-8 -*-
# Controller for managing questions in a questionnaire.
class QuestionsController < ApplicationController

  layout "admin"

  before_filter :authenticate
  before_filter :require_admin

  # Lists all questions in the system as well as a form
  # for adding template questions.
  def index
    @questions = Question.where(template: true).order(sort_order("question"))
    @question  = Question.new do |q|
      q.template = true
      q.mandatory = true
      q.qtype = "QuestionMark"
    end
  end

  def edit
    @question = Question.find params[:id]

    if @question.template
      @questions =Question.where(template: true).order(sort_order("question"))
      render action: "index"
    else
      @questionnaire = Questionnaire.find params[:questionnaire_id]
      @template_questions = Question.where(template: true).order("question ASC")
    end
  end

  def create
    @question = Question.new(params[:question])

    if @question.save
      flash[:notice] = 'Frågan skapades.'

      if params[:questionnaire_id]
        questionnaire = Questionnaire.find params[:questionnaire_id]
        questionnaire.questions << @question

        redirect_to questionnaire
      else
        redirect_to action: "index"
      end
    else
      if params[:questionnaire_id]
        @questionnaire      = Questionnaire.find params[:questionnaire_id]
        @template_questions = Question.where(template: true).order("question ASC")
        render template: "questionnaires/show"
      else
        @questions = Question.where(template: true).order(sort_order("question"))
        render action: "index"
      end
    end
  end

  def update
    @question = Question.find(params[:id])
    
    if @question.update_attributes(params[:question])
      flash[:notice] = 'Frågan uppdaterades.'

      if params[:questionnaire_id]
        questionnaire = Questionnaire.find params[:questionnaire_id]
        redirect_to questionnaire
      else
        redirect_to action: "index"
      end
    else      
      if params[:questionnaire_id]
        @questionnaire      = Questionnaire.find params[:questionnaire_id]
        @template_questions = Question.where(template: true).order("question ASC")
        render action: "edit"
      else
        @questions = Question.where(template: true).order(sort_order("question"))
        render action: "index"
      end
    end
  end

  def destroy
    question = Question.find(params[:id])
    question.destroy

    flash[:notice] = "Frågan togs bort"
    
    if params[:questionnaire_id]
      questionnaire = Questionnaire.find params[:questionnaire_id]
      redirect_to questionnaire
    else      
      redirect_to action: "index"
    end
  end

  protected

  # Sort by the questions by default.
  def sort_column_from_param(p)
    return "question" if p.blank?

    case p.to_sym
    when :qtype then "qtype"
    else
      "question"
    end
  end

end

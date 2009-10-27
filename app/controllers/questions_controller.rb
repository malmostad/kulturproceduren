# Controller for managing questions in a questionnaire.
class QuestionsController < ApplicationController

  BLABB = 3
  GRAPH_WIDTH = 500

  layout "admin"

  # Display statistical graphs over the answers to a question.
  def stat_graph
    @question = Question.find(params[:question_id])
    @occasion = Occasion.find(params[:occasion_id])
    graph = QuestionsController.question_to_graph(@question, @occasion)
    send_data(graph.to_blob,
      :disposition => 'inline',
      :type => 'image/png',
      :filename => "gruff.png")
  end
  
  # Lists all questions in the system as well as a form
  # for adding template questions.
  def index
    @questions = Question.find :all,
      :conditions => { :template => true },
      :order => sort_order("question")
    @question = Question.new do |q|
      q.template = true
      q.mandatory = true
      q.qtype = "QuestionMark"
    end
  end

  def edit
    @question = Question.find params[:id]

    if @question.template
      @questions = Question.find :all,
        :conditions => { :template => true },
        :order => sort_order("question")
      render :action => "index"
    else
      @questionaire = Questionaire.find params[:questionaire_id]
      @template_questions = Question.find :all,
        :conditions => { :template => true },
        :order => "question ASC"
    end
  end

  def create
    @question = Question.new(params[:question])

    if @question.save
      flash[:notice] = 'Frågan skapades.'

      if params[:questionaire_id]
        questionaire = Questionaire.find params[:questionaire_id]
        questionaire.questions << @question

        redirect_to questionaire
      else
        redirect_to :action => "index"
      end
    else
      if params[:questionaire_id]
        @questionaire = Questionaire.find params[:questionaire_id]
        @template_questions = Question.find :all,
          :conditions => { :template => true },
          :order => "question ASC"
        
        render :template => "questionaires/show"
      else
        @questions = Question.find :all,
          :conditions => { :template => true },
          :order => sort_order("question")

        render :action => "index"
      end
    end
  end

  def update
    @question = Question.find(params[:id])
    
    if @question.update_attributes(params[:question])
      flash[:notice] = 'Frågan uppdaterades.'

      if params[:questionaire_id]
        questionaire = Questionaire.find params[:questionaire_id]
        redirect_to questionaire
      else
        redirect_to :action => "index"
      end
    else      
      if params[:questionaire_id]
        @questionaire = Questionaire.find params[:questionaire_id]
        @template_questions = Question.find :all,
          :conditions => { :template => true },
          :order => "question ASC"

        render :action => "edit"
      else
        @questions = Question.find :all,
          :conditions => { :template => true },
          :order => sort_order("question")

        render :action => "index"
      end
    end
  end

  def destroy
    question = Question.find(params[:id])
    question.destroy

    flash[:notice] = "Frågan togs bort"
    
    if params[:questionaire_id]
      questionaire = Questionaire.find params[:questionaire_id]
      redirect_to questionaire
    else      
      redirect_to :action => "index"
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

  private
  
  # Converts a question to a graph over the answers to the question.
  def self.question_to_graph(question, occasion)
    answers = Answer.find_by_sql(
      [
        "SELECT a.*
         FROM answers a , answer_forms b
         WHERE a.answer_form_id = b.id AND b.occasion_id = ? AND a.question_id = ?",
         occasion.id , question.id
    ])

    graph = nil

    case question.qtype
    when "QuestionBool"
      num_no = 0
      num_yes = 0

      answers.each do |a|
        if a.answer_text == "y"
          num_yes += 1
        elsif a.answer_text == "n"
          num_no += 1
        end
      end

      graph = Gruff::Pie.new(GRAPH_WIDTH)
      graph.data "Ja" , num_yes
      graph.data "Nej" , num_no
    when "QuestionMchoice"
      vals = {}

      if answers.length > 0
        keys = YAML.load(answers[0].answer_text).keys
        answers.each do |a|
          YAML.load(a.answer_text).keys.each do |k|
            if vals["#{k}"].blank?
              vals["#{k}"] = 1
            else
              vals["#{k}"] += 1
            end
          end
        end
      end

      graph = Gruff::Bar.new(GRAPH_WIDTH)
      vals.keys.each { |k| graph.data k , vals["#{k}"].to_i }
      graph.minimum_value = 0

    when "QuestionText"
      graph = Gruff::Bar.new(GRAPH_WIDTH)

    when "QuestionMark"
      histogram = []
      (0..3).each { |i| histogram[i] = 0 }

      answers.each { |a| histogram[(a.answer_text.to_i-1)] += 1 }

      graph = Gruff::Bar.new(GRAPH_WIDTH)
      (0..3).each { |i| graph.data( (i+1).to_s , histogram[i]) }

    end

    graph.font = "/Library/Fonts/Arial.ttf"
    graph.right_margin = 10
    graph.left_margin = 10
    graph.title_font_size = 30
    graph.title = question.question.to_s
    graph.sort = false

    return graph
  end
end

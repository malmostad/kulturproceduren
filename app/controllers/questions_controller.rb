class QuestionsController < ApplicationController
  layout "admin"

  def stat_graph
    @question = Question.find(params[:question_id])
    @occasion = Occasion.find(params[:occasion_id])
    graph = Question::question_to_graph(@question,@occasion)
    send_data(graph.to_blob,
      :disposition => 'inline',
      :type => 'image/png',
      :filename => "gruff.png")
  end
  
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

  def sort_column_from_param(p)
    return "question" if p.blank?

    case p.to_sym
    when :qtype then "qtype"
    else
      "question"
    end
  end
end

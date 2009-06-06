class QuestionairesController < ApplicationController
  layout "standard"
  before_filter :authenticate
  require "pp"

  
  def index
    @user = current_user

    if current_user.has_role?(:admin)
      @questionaires = Questionaire.all
      render :index
    else
      flash[:error] = "Du har inte behörighet att ändra på utvärderingsenkäter"
      redirect_to "/"
    end
  end

  def show
    @user = current_user
    @qids = params[:question_id] unless params[:question_id].nil?
    
    if current_user.has_role?(:admin)
      @questionaire = Questionaire.find(params[:id])
      @all_q = Question.find(:all)
      render :admin_view
    else
      @questionaire = Questionaire.find(params[:questionaire_id])
      complete = false
      
      unless @qids.nil?
        complete = true
        @questionaire.question_ids.sort.collect {|i| i.to_s}.each do |k|
          complete = false unless @qids.keys.include?(k)
        end
      end

      if complete
        ok = true
        
        @qids.keys.each do |k|
          answer = Answer.new
          answer.question_id = k
          answer.answer = @qids[k]
          answer.occasion_id = params[:occasion_id].to_i
          answer.group_id = params[:group_id]

          if !answer.save
            flash[:error] += " Kunde inte spara svaret på fråga #{k}"
            ok = false
          end
        end
        flash[:notice] = "Tack för att du svarade på enkäten - dina svar har sparats!"
        redirect_to :controller => "questionaires", :action => "index"
      else
        render :show
      end
    end
  end

  def answer
    pp params
    redirect_to "/"
  end

  def new
    if !Event.all.collect { |e| e.questionaire.nil? }.include?(true)
      flash[:error] = "Alla evenemang har redan enkäter!"
      redirect_to :controller => "questionaires" , :action => "index"
      return
    end

    @questionaire = Questionaire.new
    @user = current_user
    @all_q = Question.find(:all)
    
    if current_user.has_role?(:admin)
      render :new
    else
      flash[:error] = "RED ALERT - UNAUTHORIZED ACCESS - ALL HANDS TO BATTLE STATIONS"
      redirect_to "/"
    end
  end

  def edit
    @questionaire = Questionaire.find(params[:id])
    @user = current_user
    @all_q = Question.find(:all)
    
    if current_user.has_role?(:admin)
      render :admin_view
    else
      flash[:error] = "RED ALERT - UNAUTHORIZED ACCESS - ALL HANDS TO BATTLE STATIONS"
      redirect_to "/"
    end
  end

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

  def update
    @questionaire = Questionaire.find(params[:id])
    if @questionaire.update_attributes(params[:questionaire])
      flash[:notice] = 'Questionaire was successfully updated.'
      redirect_to(@questionaire) 
    else
      render :action => "edit" 
    end
  end

  def destroy
    @questionaire = Questionaire.find(params[:id])
    @questionaire.destroy

    respond_to do |format|
      format.html { redirect_to(questionaires_url) }
      format.xml  { head :ok }
    end
  end
end

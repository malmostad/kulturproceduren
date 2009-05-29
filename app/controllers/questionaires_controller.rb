class QuestionairesController < ApplicationController
  layout "standard"
  before_filter :authenticate
  require "pp"
  # GET /questionaires
  # GET /questionaires.xml
  def index
    @user = User.find_by_id(session[:current_user_id])

    if @user.roles.include?(Role.find_by_name("Administratör"))
      @questionaires = Questionaire.all
      render :index
    else
      @questionaires = Array.new
      tot_answers = 0
      tot_tickets = 1
      @user.groups.each do |g|
        g.events.each do |e|
          e.occasions.each do |o|
            tot_answers = Answer.find(:all, :conditions => "occasion_id = #{o.id} and group_id = #{g.id}" ).length
            tot_tickets = Ticket.find(:all, :conditions => "occasion_id = #{o.id} and group_id = #{g.id} and ( state = #{Ticket::BOOKED} or state = #{Ticket::USED} )" ).length
            puts "e = #{e.name} , o = #{o.date} , g = #{g.name} , tot_answers = #{tot_answers} , tot_ticket = #{tot_tickets}"
            # TODO Dagens datum istället för hårdkodat
            if tot_tickets > 0 and tot_answers == 0 and  e.last_occasion.date < Date.new(2009,12,12) and not @questionaires.include?(e.questionaire)
              puts "pushing event #{e.name}"
              @questionaires.push(e.questionaire)
            end
          end
        end
      end
      pp @questionaires
      render :mina_enkater
    end
  end

  # GET /questionaires/1
  # GET /questionaires/1.xml
  def show
    @user = User.find_by_id(session[:current_user_id])
    @qids = params[:question_id] unless params[:question_id].nil?
    if @user.roles.include?(Role.find_by_name("Administratör"))
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
      if (complete )
        ok = true
        @qids.keys.each do |k|
          answer = Answer.new
          answer.question_id = k
          answer.answer = @qids[k]
          answer.occasion_id = params[:occasion_id]
          answer.group_id = params[:group_id]
          if not answer.save
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

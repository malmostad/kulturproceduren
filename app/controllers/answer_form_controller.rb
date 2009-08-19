# Controller for managing answer forms
class AnswerFormController < ApplicationController
  layout "standard"

  # Saves the answers to a questionnaire
  def submit
    unless AnswerForm.exists?(params[:answer_form_id])
      flash[:error] = "Ogiltig utvärderingsenkät"
      redirect_to "/"
      return
    end

    @answer_form = AnswerForm.find(params[:answer_form_id])

    if @answer_form.completed
      flash[:error] = "Utvärderingsenkäten är redan besvarad"
      redirect_to "/"
      return
    end

    @answer = params[:answer].blank? ? {} : params[:answer]
    @qids = []
    @non_answered_mandatory_questions = []

    @answer.keys.each { |k| @qids << k unless @answer["#{k}"].blank? } unless @answer.blank? 

    unless @qids.blank?
      @non_answered_mandatory_questions = @answer_form.questionaire.questions.select { |q| q.mandatory }.map {|q| q.id } - @qids.map { |k| k.to_i }.sort

      if @non_answered_mandatory_questions.blank?

        @answer.each do |qid , ans|
          answer = Answer.new
          answer.question_id = qid
          answer.answer_text = ans
          answer.answer_form = @answer_form
          answer.save!
        end

        @answer_form.completed = true
        @answer_form.save!

        flash[:notice] = "Tack för att du svarade på utvärderingsenkäten"
        redirect_to "/"
      end
    end
  end

end

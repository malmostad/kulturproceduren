# -*- encoding : utf-8 -*-
# Controller for managing answer forms
class AnswerFormController < ApplicationController
  layout "standard"

  # Saves the answers to a questionnaire
  def submit
    unless AnswerForm.exists?(params[:answer_form_id])
      flash[:error] = "Ogiltig utvärderingsenkät"
      redirect_to root_url()
      return
    end

    @answer_form = AnswerForm.find(params[:answer_form_id])

    if @answer_form.completed
      flash[:error] = "Utvärderingsenkäten är redan besvarad"
      redirect_to root_url()
      return
    end

    @answer = params[:answer] || {}

    if !@answer.blank? && @answer_form.answer(params[:answer])
      flash[:notice] = "Tack för att du svarade på utvärderingsenkäten"
      redirect_to root_url()
    end

  end

end

class SchoolPriosController < ApplicationController

  before_filter :authenticate
  before_filter :require_admin

  before_filter :load_school
  
  def move_up
    swap @school, @school.above_in_prio
    redirect_to @school.district
  end

  def move_down
    swap @school, @school.below_in_prio
    redirect_to @school.district
  end

  private

  def swap(s1, s2)
    return unless s1 && s2
    s1.school_prio.prio, s2.school_prio.prio = s2.school_prio.prio, s1.school_prio.prio

    s1.school_prio.save!
    s2.school_prio.save!
  end

  def load_school
    begin
      @school = School.find params[:id], :include => :school_prio
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "En befintlig skola måste väljas för att kunna ändra dess prioritering"
      redirect_to schools_url()
    end
  end
end

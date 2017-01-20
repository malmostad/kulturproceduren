class AdminController < ApplicationController
  layout "application"

  def email_search
    @email_address = params[:email_address]
    if not @email_address.nil? and not @email_address.blank?
      @districts = District.where('contacts ilike ?', '%'+@email_address+'%')
      @schools = School.where('contacts ilike ?', '%'+@email_address+'%')
      @groups = Group.includes(:school).where('contacts ilike ?', '%'+@email_address+'%')
    end
  end

end
#
# select contacts from schools;
# select contacts from groups;
# select contacts from districts;

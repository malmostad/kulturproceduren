# Controller for managing districts
class VersionsController < ApplicationController
  layout "admin"
  
  before_filter :authenticate
  before_filter :require_admin


  def revert
    version = PaperTrail::Version.find(params[:id])

    item = version.reify
    item.save!

    flash[:notice] = "Återställde till en äldre version"
    redirect_to version.item
  end
end

# Controller for managing districts
class VersionsController < ApplicationController
  before_filter :authenticate
  before_filter :require_admin


  def revert
    version = PaperTrail::Version.find(params[:id])

    item = version.reify

    # Check if a new version was added
    count_before = item.versions.count

    item.save!

    if !version.extra_data.blank? && item.respond_to?(:set_extra_data_from_version!)
      # Force a new version before setting the extra data
      # if no version was added above
      item.touch_with_version if item.versions.count == count_before

      item.set_extra_data_from_version!(version.extra_data)
    end

    flash[:notice] = "Återställde till en äldre version"
    redirect_to version.item
  end
end

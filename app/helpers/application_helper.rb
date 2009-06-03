# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def active_by_controller(*names)
    "active" if names.include?(params[:controller])
  end

  def active_by_action(controller, *names)
    "active" if params[:controller] == controller && names.include?(params[:action])
  end

  def empty?(a)
    a.nil? || a.strip.empty?
  end

  def qualified_url(url)
    unless url =~ /^http:\/\//i
      url = "http://" + url
    end

    url
  end
end

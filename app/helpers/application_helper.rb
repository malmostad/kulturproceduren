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

  def paragraphize(text, tag_attrs = '', escape = true)
    text = h(text) if escape
    "<p #{tag_attrs}>" + text.gsub(/^\s*$/, "</p><p #{tag_attrs}>") + "</p>"
  end
  def linebreakize(text, escape = true)
    text = h(text) if escape
    text.split($/).join("<br/>")
  end
end

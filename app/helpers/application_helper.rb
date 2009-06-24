# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def active_by_controller(*names)
    " active " if names.include?(params[:controller])
  end

  def active_by_action(controller, *names)
    " active " if params[:controller] == controller && names.include?(params[:action])
  end

  def disabled_if(c)
    ' disabled="disabled" ' if c
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

  def sort_link(title, column, options = {})
    condition = options[:unless] if options.has_key?(:unless)
    sort_dir = params[:d] == 'up' && params[:c] == column ? 'down' : 'up'
    link_to_unless condition, title,
      :overwrite_params => { :c => column, :d => sort_dir }
  end

end

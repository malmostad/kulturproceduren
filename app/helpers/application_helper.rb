# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # Returns the css class <tt>active</tt> if the current controller is among
  # the names in the arguments.
  #
  # Used in navigation menus to get an indicator of the currently active page.
  def active_by_controller(*names)
    " active " if names.include?(params[:controller])
  end

  # Returns the css class <tt>active</tt> if the current action is an action in the given
  # controller and is among the names in the arguments.
  #
  # Used in navigation menus to get an indicator of the currently active page.
  def active_by_action(controller, *names)
    " active " if params[:controller] == controller && names.include?(params[:action])
  end

  # Returns a disable HTML attribute if the argument is <tt>false</tt>.
  def disabled_if(c)
    ' disabled="disabled" ' if c
  end

  # Convenience method to see if a string is really empty (= not nil, empty,
  # or filled with whitespace).
  def empty?(a)
    a.nil? || a.strip.empty?
  end

  # Creates a fully qualified URL if the given <tt>url</tt> is not qualified.
  def qualified_url(url)
    unless url =~ /^http:\/\//i
      url = "http://" + url
    end

    url
  end

  # Turns a text into HTML paragraphs. Paragraphs should be separated
  # by empty lines.
  def paragraphize(text, tag_attrs = '', escape = true)
    text = html_escape(text) if escape
    lines = text.split(/^\s*$/).collect { |l| l.strip.gsub(/[\r\n]+/, '<br/>') }
    paragraphs = "<p #{tag_attrs}>" + lines.join("</p><p #{tag_attrs}>") + "</p>"
    return paragraphs.html_safe
  end
  # Inserts HTML breaks at line breaks.
  def linebreakize(text, escape = true)
    text = html_escape(text) if escape
    text.split($/).join("<br/>").html_safe
  end

  # Common description rendering
  def show_description(description)
    return "" if description.blank?
    if description.include?("<p")
      content_tag(:div,
        sanitize(
          description,
          tags: %w(a b strong i em span p ul ol li h1 h2 h3 h4 h5 h6 blockquote),
          attributes: %w(href target title style)
        ),
        class: "description"
      )
    else
      paragraphize(description, 'class="description"')
    end
  end

  # Creates a link for sorting a table based on a column.
  #
  # [<tt>title</tt>] The link's text
  # [<tt>column</tt>] The sort column
  #
  # Options:
  #
  # [<tt>:unless</tt>] A condition for link_to_unless
  def sort_link(title, column, options = {})
    condition = options[:unless] if options.has_key?(:unless)
    sort_dir = params[:d] == 'up' && params[:c] == column ? 'down' : 'up'
    link_to_unless condition, title,
      params.merge(c: column, d: sort_dir)
  end

  # Generates an image tag for uploaded images
  #
  # [<tt>image</tt>] The image model
  # [<tt>thumb</tt>] Indicates if the image tag should show the thumbnail or not
  def uploaded_image_tag(image, thumb = false)
    options = {
      alt: html_escape(image.description),
      title: html_escape(image.description)
    }

    image_path = "/images/"

    if ActionController::Base.relative_url_root
      image_path = ActionController::Base.relative_url_root + image_path
    end

    if thumb
      options[:width] = image.thumb_width
      options[:height] = image.thumb_height
      options[:src] = image_path + image.thumb_url
    else
      options[:width] = image.width
      options[:height] = image.height
      options[:src] = image_path + image.image_url
    end

    return tag("img", options).html_safe
  end

  # Generates a login link that returns the user to the
  # current page, or to the specified URL.
  def login_link(text, url = nil)
    link_to text,
      controller: "login",
      action: "index",
      return_to: url || url_for(request.query_parameters.update(request.path_parameters))
  end

  # Wrapper around <tt>cache()</tt> do for conditional caching.
  def conditional_cache(condition, name = {}, options = nil, &block)
    if condition
      cache(name, options, &block)
    else
      capture(&block)
    end
  end

  # Converts a date to the format "(ht|vt)$year"
  def to_term(date)
    "#{date.month > 6 ? "ht" : "vt"}#{date.year}"
  end

  # Includes wysiwyg libraries and initialization files
  def wysiwyg_init
    render partial: "shared/wysiwyg_init"
  end

  # Change the default link renderer for will_paginate
  def will_paginate(collection_or_options = nil, options = {})
    if collection_or_options.is_a?(Hash)
      options, collection_or_options = collection_or_options, nil
    end
    unless options[:renderer]
      options = options.merge renderer: KPWillPaginate::LinkRenderer
    end
    super *[collection_or_options, options].compact
  end


  # Renders a form for selecting a group
  def group_selection_form(occasion: nil, return_to: nil)
    state = session[:group_selection] || {}
    return_to ||= url_for(request.query_parameters.update(request.path_parameters))

    group_options = group_selection_group_options(occasion, state[:school_id])

    render partial: "shared/group_selection_form",
      locals: { occasion: occasion, return_to: return_to, state: state, group_options: group_options }
  end


  private

  def group_selection_group_options(occasion, school_id)
    return [] if school_id.blank?

    groups = Group.where(school_id: school_id).order("name")

    if occasion
      groups = groups.select { |g| g.available_tickets_by_occasion(occasion) > 0 }

      return [[ "Välj klass/avdelning", nil ]] + groups.collect { |g| [
        g.name + (occasion.event.alloted_group? ? " (#{g.available_tickets_by_occasion(occasion)} platser)" : ""),
        g.id
      ] }
    else
      return [[ "Välj klass/avdelning", nil ]] + groups.collect { |g| [ g.name, g.id ] }
    end

  end
end

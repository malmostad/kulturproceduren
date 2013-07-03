# Form builder implementing the markup guidelines for malmo.se
# 
# Fields are encapsulated in rows with labels automatically
# added, and error messages added before/above the label
# and the field.
class KPFormBuilder < ActionView::Helpers::FormBuilder

  # All form fields where the field's label comes before the actual field
  pre_labeled = %w{text_area file_field text_field password_field date_select datetime_select time_select collection_select select country_select time_zone_select}
  # All form fields where the field's label comes after the actual field
  post_labeled = %w{check_box radio_button}

  # Dynamically override the original form builder methods
  pre_labeled.each do |name|
    # Define a method calling the super method for later renaming
    define_method(name) do
      super
    end

    # Aliases the method so the parent versions of the methods can be
    # accessed by prepending +single_+ to the method name
    alias_method "single_#{name}".to_sym, name.to_sym

    # Define the new methods implementing the new markup
    define_method(name) do |field, *args|
      options = args.last.is_a?(Hash) ? args.pop : {}

      label = label(field, options.delete(:label), :class => options.delete(:label_class))
      error = validation_error_message(field)
      help = options.delete(:field_help)
      row_hidden = options.delete(:row_hidden)

      row error + label + field(super, help), row_class(field, !error.blank?), row_hidden
    end
  end

  # Dynamically override the original form builder methods
  post_labeled.each do |name|
    # Define a method calling the super method for later renaming
    define_method(name) do
      super
    end

    # Aliases the method so the parent versions of the methods can be
    # accessed by prepending +single_+ to the method name
    alias_method "single_#{name}".to_sym, name.to_sym
    
    # Define the new methods implementing the new markup
    define_method(name) do |field, *args|
      options = args.last.is_a?(Hash) ? args.pop : {}

      label = label(field, options.delete(:label), :class => options.delete(:label_class))
      error = validation_error_message(field)
      help = options.delete(:field_help)
      row_hidden = options.delete(:row_hidden)

      row error + super + label + field_help(help), row_class(field, !error.blank?, "post-label-form-row"), row_hidden
    end
  end

  def validation_error_message(field)
    if @object.errors.include?(field)
      error = @object.errors[field]
      @template.content_tag(
        :div,
        error.is_a?(Array) ? error.first : error,
        :class => "validation-error-message alert-field"
      )
    else
      "".html_safe
    end
  end

  # Generates a container displaying an indicator that validation of the
  # form has failed, if the object has any validation errors
  def validation_error_indicator
    unless @object.errors.empty?
      @template.content_tag(
        :div,
        "Vänligen korrigera markerade uppgifter nedan.",
        :class => "validation-error-indicator alert"
      )
    else
      ""
    end
  end

  # Generates markup for the field row
  def row(content = '', extra_class = '', row_hidden = false, &block)
    if block_given?
      content = @template.capture(&block)
    end
    
    return @template.content_tag :div, content,
      :class => "form-row " + extra_class,
      :style => (row_hidden ? "display: none;" : "")
  end

  # Generates markup for the field, encapsulating it in a container
  def field(content = '', help = '', &block)
    if block_given?
      content = @template.capture(&block)
    end

    content += field_help(help)

    return @template.content_tag(:div, content, :class => "input-container")
  end

  # Generates a fieldset container with an optional legend encapsulating
  # multiple field of rows.
  def fields(title = '', extra_classes = '', &block)
    raise ArgumentError, "Missing block" unless block_given?

    contents = @template.capture(&block)
    title    = title.blank? ? title.html_safe : @template.content_tag(:legend, @template.content_tag(:span, title))
    cls      = title.blank? ? "" : "with-legend "
    cls      << extra_classes

    return @template.content_tag(:fieldset, title + contents, :class => cls)
  end

  # Generates a container for the form submit buttons
  def buttons(&block)
    raise ArgumentError, "Missing block" unless block_given?
    contents = @template.capture(&block)
    return @template.content_tag(:div, contents, :class => "form-buttons")
  end

  # Generates a title for the form
  def title(text)
    @template.content_tag(:h2, text)
  end

  # Generates a hint for a given field row
  def hint(&block)
    raise ArgumentError, "Missing block" unless block_given?

    contents = @template.capture(&block)
    return @template.content_tag(:p, contents, :class => "hint")
  end

  # Generates a hint for a given field row if the given condition is true
  def conditional_hint(condition, &block)
    raise ArgumentError, "Missing block" unless block_given?

    if condition
      contents = @template.capture(&block)
      return @template.content_tag(:p, contents, :class => "hint")
    end
  end

  # Generates a help text for a field.
  def field_help(text)
    unless text.blank?
      @template.content_tag(:span, text, :class => "field-help")
    else
      ''
    end
  end
  
  
  private

  # Generates a row class based on the field name and eventual errors
  def row_class(field, error_test, extra_classes = '')
    "#{field.to_s.sub(/\?$/, '')}-field-row #{"validation-error" if error_test} #{extra_classes}"
  end

end

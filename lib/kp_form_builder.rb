
class KPFormBuilder < ActionView::Helpers::FormBuilder

  pre_labeled = %w{text_area file_field text_field password_field date_select datetime_select time_select collection_select select country_select time_zone_select}
  post_labeled = %w{check_box radio_button}

  pre_labeled.each do |name|
    define_method(name) do
      super
    end

    alias_method "single_#{name}".to_sym, name.to_sym

    define_method(name) do |field, *args|
      options = args.last.is_a?(Hash) ? args.pop : {}

      label = label(field, options.delete(:label), :class => options.delete(:label_class))
      error = error_message_on(field)
      help = options.delete(:field_help)
      row_hidden = options.delete(:row_hidden)

      row error + label + field(super, help), row_class(field, !error.blank?), row_hidden
    end
  end

  post_labeled.each do |name|
    define_method(name) do
      super
    end

    alias_method "single_#{name}".to_sym, name.to_sym
    
    define_method(name) do |field, *args|
      options = args.last.is_a?(Hash) ? args.pop : {}

      label = label(field, options.delete(:label), :class => options.delete(:label_class))
      error = error_message_on(field)
      help = options.delete(:field_help)
      row_hidden = options.delete(:row_hidden)

      row error + super + label + field_help(help), row_class(field, !error.blank?, "post-label-row"), row_hidden
    end
  end

  def validation_error_indicator
    unless @object.errors.empty?
      @template.content_tag(:div, "Vänligen korrigera markerade uppgifter nedan.", :class => "validation-error-indicator alert")
    else
      ""
    end
  end

  def row(content = '', extra_class = '', row_hidden = false, &block)
    if block_given?
      content = @template.capture(&block)
    end
    
    tag = @template.content_tag :div, content,
      :class => "form-row " + extra_class,
      :style => (row_hidden ? "display: none;" : "")

    if block_given?
      @template.concat tag
    end

    tag
  end

  def field(content = '', help = '', &block)
    if block_given?
      content = @template.capture(&block)
    end

    content += field_help(help)
    tag = @template.content_tag(:div, content, :class => "input-container")

    if block_given?
      @template.concat tag
    end

    tag
  end

  def fields(title = '', &block)
    raise ArgumentError, "Missing block" unless block_given?

    contents = @template.capture(&block)
    title = @template.content_tag(:legend, @template.content_tag(:span, title)) unless title.blank?

    @template.concat @template.content_tag(:fieldset, contents + title)
  end

  def buttons(&block)
    raise ArgumentError, "Missing block" unless block_given?
    contents = @template.capture(&block)
    @template.concat @template.content_tag(:div, contents, :class => "form-buttons")
  end

  def title(text)
    @template.content_tag(:h2, text)
  end

  def hint(&block)
    raise ArgumentError, "Missing block" unless block_given?

    contents = @template.capture(&block)
    @template.concat @template.content_tag(:p, contents, :class => "hint")
  end

  def conditional_hint(condition, &block)
    raise ArgumentError, "Missing block" unless block_given?

    if condition
      contents = @template.capture(&block)
      @template.concat @template.content_tag(:p, contents, :class => "hint")
    end
  end

  def field_help(text)
    unless text.blank?
      @template.content_tag(:span, text, :class => "field-help")
    else
      ''
    end
  end
  
  
  private

  def row_class(field, error_test, extra_classes = '')
    "#{field.to_s.sub(/\?$/, '')}-field-row #{"validation-error" if error_test} #{extra_classes}"
  end

end

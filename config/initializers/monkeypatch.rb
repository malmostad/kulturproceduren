

ActionView::Helpers::Tags::Base.class_eval do
  private

  #
  # *MONKEYPATCH*
  #
  # <tt>actionpack-4.0.4/lib/action_view/helpers/tags/base.rb</tt>
  #
  # Overrides the method generating the DOM ID for a field
  #
  def tag_id
    "kp-#{sanitized_object_name}-#{sanitized_method_name}"
  end

  #
  # *MONKEYPATCH*
  #
  # <tt>actionpack-4.0.4/lib/action_view/helpers/tags/base.rb</tt>
  #
  # Overrides the method generating the DOM ID for a field with an index
  #
  def tag_id_with_index(index)
    "kp-#{sanitized_object_name}-#{index}-#{sanitized_method_name}"
  end
end



ActionView::Helpers::DateTimeSelector.class_eval do
  private

  #
  # *MONKEYPATCH*
  #
  # <tt>actionpack-4.0.4/lib/action_view/helpers/date_helper.rb</tt>
  #
  # Overrides the DOM ID generator for date/time selectors
  #
  def input_id_from_type(type)
    id = input_name_from_type(type).gsub(/([\[\(])|(\]\[)/, '_').gsub(/[\]\)]/, '')
    id = @options[:namespace] + '_' + id if @options[:namespace]

    # MONKEYPATCH: Added kp- prefix
    "kp-#{id}"
  end
end



ActionView::Helpers::FormBuilder.class_eval do

  #
  # *MONKEYPATCH*
  #
  # <tt>actionpack-4.0.4/lib/action_view/helpers/form_helper.rb</tt>
  #
  # Overrides the method generating the submit button, prefixing the submit button's DOM ID.
  #
  def submit(value=nil, options={})
    value, options = nil, value if value.is_a?(Hash)
    value ||= submit_default_value
    # MONKEYPATCH: Added kp- prefix to id
    @template.submit_tag(value, options.reverse_merge(id: "kp-#{object_name}-submit"))
  end
end


module ActionView::Helpers::FormTagHelper

  #
  # *MONKEYPATCH*
  #
  # <tt>actionpack-4.0.4/lib/action_view/helpers/form_tag_helper.rb</tt>
  #
  # Overrides the DOM ID generation, prefixing the ID
  #
  def radio_button_tag(name, value, checked = false, options = {})
    sanitized_name  = name.to_s.gsub(']','').gsub(/[^-a-zA-Z0-9:.]/, "_")
    sanitized_value = value.to_s.gsub(']','').gsub(/[^-a-zA-Z0-9:.]/, "_")

    # MONKEYPATCH: Added kp- prefix to id
    html_options = { "type" => "radio", "name" => name, "id" => "kp-#{sanitized_name}_#{sanitized_value}", "value" =>     value }.update(options.stringify_keys)
    html_options["checked"] = "checked" if checked
    tag :input, html_options
  end

  #
  # *MONKEYPATCH*
  #
  # <tt>actionpack-4.0.4/lib/action_view/helpers/form_tag_helper.rb</tt>
  #
  # Overrides the DOM ID generation to prefix the ID
  #
  def sanitize_to_id(name)
    # MONKEYPATCH: Added kp- prefix
    "kp-" + name.to_s.gsub(']','').gsub(/[^-a-zA-Z0-9:.]/, "_")
  end
end



module ActionController::RecordIdentifier

  #
  # *MONKEYPATCH*
  #
  # <tt>actionpack-4.0.4/lib/action_controller/record_identifier.rb</tt>
  #
  # Overrides the DOM class generator to prefix the class
  #
  def dom_class(record_or_class, prefix = nil)
    ActiveSupport::Deprecation.warn(INSTANCE_MESSAGE % 'dom_class')

    singular = ActiveModel::Naming.param_key(record_or_class)
    # MONKEYPATCH: Added kp-prefix
    prefix ? "kp-#{prefix}#{JOIN}#{singular}" : "kp-#{singular}"
  end
end

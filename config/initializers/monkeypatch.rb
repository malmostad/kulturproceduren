# Monkeypatching of Rails default classes
#
# Used to coerce the Rails classes into conforming to the markup
# guidelines for malmo.se

module ActionView
  module Helpers
    class InstanceTag
      # Fixes the id generation to include stripping of dashes
      def to_radio_button_tag(tag_value, options = {})
        options = DEFAULT_RADIO_OPTIONS.merge(options.stringify_keys)
        options["type"]     = "radio"
        options["value"]    = tag_value

        if options.has_key?("checked")
          cv = options.delete "checked"
          checked = cv == true || cv == "checked"
        else
          checked = self.class.radio_button_checked?(value(object), tag_value)
        end

        options["checked"]  = "checked" if checked
        pretty_tag_value    = tag_value.to_s.gsub(/\s/, "_").gsub(/[^A-Za-z0-9-]/, "").downcase
        options["id"]     ||= defined?(@auto_index) ?
          "#{tag_id_with_index(@auto_index)}_#{pretty_tag_value}" :
          "#{tag_id}_#{pretty_tag_value}"

        add_default_name_and_id(options)

        tag("input", options)
      end

      private
      # Overrides the method generating the DOM ID for a field
      def tag_id
        "kp-#{sanitized_object_name}-#{sanitized_method_name}"
      end
      # Overrides the method generating the DOM ID for a field with an index
      def tag_id_with_index(index)
        "kp-#{sanitized_object_name}-#{index}-#{sanitized_method_name}"
      end
    end

    class DateTimeSelector
      private
      # Overrides the DOM ID generator for date/time selectors
      def input_id_from_type(type)
        "kp-" + input_name_from_type(type).gsub(/([\[\(])|(\]\[)/, '-').gsub(/[\]\)]/, '')
      end
    end

    class FormBuilder
      # Overrides the method generating the submit button, prefixing the submit button's DOM ID.
      def submit(value = "Save changes", options = {})
        @template.submit_tag(value, options.reverse_merge(:id => "kp-#{object_name}_submit"))
      end
    end

    module FormTagHelper
      # Adds ID sanitation when creating the DOM Id.
      def text_area_tag(name, content = nil, options = {})
        options.stringify_keys!

        if size = options.delete("size")
          options["cols"], options["rows"] = size.split("x") if size.respond_to?(:split)
        end

        content_tag :textarea, content, { "name" => name, "id" => sanitize_to_id(name) }.update(options.stringify_keys)
      end

      # Overrides the DOM ID generation, prefixing the ID
      def radio_button_tag(name, value, checked = false, options = {})
        pretty_tag_value = value.to_s.gsub(/\s/, "_").gsub(/(?!-)\W/, "").downcase
        pretty_name = name.to_s.gsub(/\[/, "_").gsub(/\]/, "")
        html_options = { "type" => "radio", "name" => name, "id" => "kp-#{pretty_name}_#{pretty_tag_value}", "value" => value }.update(options.stringify_keys)
        html_options["checked"] = "checked" if checked
        tag :input, html_options
      end

      # Overrides the DOM ID generation to prefix the ID
      def sanitize_to_id(name)
        "kp-" + name.to_s.gsub(']','').gsub(/[^-a-zA-Z0-9:.]/, "_")
      end
    end

    module ActiveRecordHelper
      # Overrides the error message for a specific field to adhere to
      # the markup guidelines for malmo.se
      def error_message_on(object, method, *args)
        options = args.extract_options!
        unless args.empty?
          ActiveSupport::Deprecation.warn('error_message_on takes an option hash instead of separate ' +
                                          'prepend_text, append_text, and css_class arguments', caller)

          options[:prepend_text] = args[0] || ''
          options[:append_text] = args[1] || ''
          options[:css_class] = args[2] || 'validation-error-message alert-field'
        end
        options.reverse_merge!(:prepend_text => '', :append_text => '', :css_class => 'validation-error-message alert-field')

        if (obj = (object.respond_to?(:errors) ? object : instance_variable_get("@#{object}"))) &&
          (errors = obj.errors.on(method))
          content_tag(
            "div",
            "#{options[:prepend_text]}#{ERB::Util.html_escape(errors.is_a?(Array) ? errors.first : errors)}#{options[:append_text]}",
            :class => options[:css_class]
          )
        else
          ''
        end
      end
    end
  end
end

module ActionController
  module RecordIdentifier
    # Overrides the DOM class generator to prefix the class
    def dom_class(record_or_class, prefix = nil)
      singular = singular_class_name(record_or_class)
      prefix ? "kp-#{prefix}#{JOIN}#{singular}" : "kp-#{singular}"
    end
  end
end

# No reporting of field errors in the summary in the beginnning of the form
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  html_tag
end

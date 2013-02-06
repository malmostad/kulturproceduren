# Monkeypatching of Rails default classes
#
# Used to coerce the Rails classes into conforming to the markup
# guidelines for malmo.se

module ActionView
  module Helpers
    class InstanceTag
      private
      # *MONKEYPATCH*
      #
      # <tt>actionpack-2.3.16/lib/action_view/helpers/form_helper.rb:949</tt>
      #
      # Overrides the method generating the DOM ID for a field
      def tag_id
        # MONKEYPATCH: Added kp- prefix
        "kp-#{sanitized_object_name}-#{sanitized_method_name}"
      end
      # *MONKEYPATCH*
      #
      # <tt>actionpack-2.3.16/lib/action_view/helpers/form_helper.rb:953</tt>
      #
      # Overrides the method generating the DOM ID for a field with an index
      def tag_id_with_index(index)
        # MONKEYPATCH: Added kp- prefix
        "kp-#{sanitized_object_name}-#{index}-#{sanitized_method_name}"
      end
    end

    class DateTimeSelector
      private
      # *MONKEYPATCH*
      #
      # <tt>actionpack-2.3.16/lib/action_view/helpers/date_helper.rb:888</tt>
      #
      # Overrides the DOM ID generator for date/time selectors
      def input_id_from_type(type)
        # MONKEYPATCH: Added kp- prefix
        "kp-" + input_name_from_type(type).gsub(/([\[\(])|(\]\[)/, '-').gsub(/[\]\)]/, '')
      end
    end

    class FormBuilder
      # *MONKEYPATCH*
      #
      # <tt>actionpack-2.3.16/lib/action_view/helpers/form_helper.rb:1059</tt>
      #
      # Overrides the method generating the submit button, prefixing the submit button's DOM ID.
      def submit(value = "Save changes", options = {})
        # MONKEYPATCH: Added kp- prefix to id
        @template.submit_tag(value, options.reverse_merge(:id => "kp-#{object_name}_submit"))
      end
    end

    module FormTagHelper
      # *MONKEYPATCH*
      #
      # <tt>actionpack-2.3.16/lib/action_view/helpers/form_tag_helper.rb:317</tt>
      #
      # Overrides the DOM ID generation, prefixing the ID
      def radio_button_tag(name, value, checked = false, options = {})
        pretty_tag_value = value.to_s.gsub(/\s/, "_").gsub(/(?!-)\W/, "").downcase
        pretty_name = name.to_s.gsub(/\[/, "_").gsub(/\]/, "")
        # MONKEYPATCH: Added kp- prefix to id
        html_options = { "type" => "radio", "name" => name, "id" => "kp-#{pretty_name}_#{pretty_tag_value}", "value" => value }.update(options.stringify_keys)
        html_options["checked"] = "checked" if checked
        tag :input, html_options
      end

      # *MONKEYPATCH*
      #
      # <tt>actionpack-2.3.16/lib/action_view/helpers/form_tag_helper.rb:484</tt>
      #
      # Overrides the DOM ID generation to prefix the ID
      def sanitize_to_id(name)
        # MONKEYPATCH: Added kp- prefix
        "kp-" + name.to_s.gsub(']','').gsub(/[^-a-zA-Z0-9:.]/, "_")
      end
    end

    module ActiveRecordHelper
      # *MONKEYPATCH*
      #
      # <tt>actionpack-2.3.16/lib/action_view/helpers/active_record_helper.rb:109</tt>
      #
      # Overrides the error message for a specific field to adhere to
      # the markup guidelines for malmo.se
      def error_message_on(object, method, *args)
        options = args.extract_options!
        unless args.empty?
          ActiveSupport::Deprecation.warn('error_message_on takes an option hash instead of separate ' +
                                          'prepend_text, append_text, and css_class arguments', caller)

          options[:prepend_text] = args[0] || ''
          options[:append_text] = args[1] || ''
          # MONKEYPATCH: Changed the default CSS class
          options[:css_class] = args[2] || 'validation-error-message alert-field'
        end
        # MONKEYPATCH: Changed the default CSS class
        options.reverse_merge!(:prepend_text => '', :append_text => '', :css_class => 'validation-error-message alert-field')

        if (obj = (object.respond_to?(:errors) ? object : instance_variable_get("@#{object}"))) &&
          (errors = obj.errors.on(method))
          content_tag(
            "div",
            "#{options[:prepend_text]}#{ERB::Util.html_escape(errors.is_a?(Array) ? errors.first : errors)}#{options[:append_text]}".html_safe,
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
    # *MONKEYPATCH*
    #
    # <tt>actionpack-2.3.4/lib/action_controller/record_identifier.rb:61</tt>
    #
    # Overrides the DOM class generator to prefix the class
    def dom_class(record_or_class, prefix = nil)
      singular = singular_class_name(record_or_class)
      # MONKEYPATCH: Added kp- prefix
      prefix ? "kp-#{prefix}#{JOIN}#{singular}" : "kp-#{singular}"
    end
  end
end

# No reporting of field errors in the summary in the beginnning of the form
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  html_tag
end

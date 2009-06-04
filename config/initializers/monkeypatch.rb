# Monkeypatching of Rails default classes

# Prefixed form ids
module ActionView
  module Helpers
    class InstanceTag
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
      def tag_id
        "kp-#{sanitized_object_name}-#{sanitized_method_name}"
      end
      def tag_id_with_index(index)
        "kp-#{sanitized_object_name}-#{index}-#{sanitized_method_name}"
      end
    end

    class DateTimeSelector
      private
      def input_id_from_type(type)
        "kp-" + input_name_from_type(type).gsub(/([\[\(])|(\]\[)/, '-').gsub(/[\]\)]/, '')
      end
    end

    class FormBuilder
      def submit(value = "Save changes", options = {})
        @template.submit_tag(value, options.reverse_merge(:id => "kp-#{object_name}_submit"))
      end
    end

    module FormTagHelper
      def text_area_tag(name, content = nil, options = {})
        options.stringify_keys!

        if size = options.delete("size")
          options["cols"], options["rows"] = size.split("x") if size.respond_to?(:split)
        end

        content_tag :textarea, content, { "name" => name, "id" => sanitize_to_id(name) }.update(options.stringify_keys)
      end
      def sanitize_to_id(name)
        "kp-" + name.to_s.gsub(']','').gsub(/[^-a-zA-Z0-9:.]/, "_")
      end
    end
  end
end

module ActionController
  module RecordIdentifier
    def dom_class(record_or_class, prefix = nil)
      singular = singular_class_name(record_or_class)
      prefix ? "kp-#{prefix}#{JOIN}#{singular}" : "kp-#{singular}"
    end
  end
end

# More graceful field error indication
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  if html_tag =~ /<(input|textarea|select|label)[^>]+class=/
    class_attribute = html_tag =~ /class=['"]/
    html_tag.insert(class_attribute + 7, "error ")
  elsif html_tag =~ /<(input|textarea|select|label)/
    first_whitespace = html_tag =~ /\s/
    html_tag[first_whitespace] = " class=\"error\" "
  end
  html_tag
end


require 'cgi'
require 'action_view/helpers/tag_helper'

module ActionView
  module Helpers
    # Provides a number of methods for creating form tags that doesn't rely on an Active Record object assigned to the template like
    # FormHelper does. Instead, you provide the names and values manually.
    #
    # NOTE: The HTML options <tt>disabled</tt>, <tt>readonly</tt>, and <tt>multiple</tt> can all be treated as booleans. So specifying
    # <tt>:disabled => true</tt> will give <tt>disabled="disabled"</tt>.

  end
end


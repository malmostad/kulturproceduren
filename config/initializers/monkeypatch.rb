# Monkeypatching of Rails default classes

# Prefixed form ids
module ActionView
  module Helpers
    class InstanceTag
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


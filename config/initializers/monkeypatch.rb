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

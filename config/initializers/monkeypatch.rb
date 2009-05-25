# Monkeypatching of Rails default classes

module ActionView
  module Helpers
    class InstanceTag

      private

      # Prefixed form ids
      def tag_id
        "kp-#{sanitized_object_name}-#{sanitized_method_name}"
      end

      def tag_id_with_index(index)
        "kp-#{sanitized_object_name}-#{index}-#{sanitized_method_name}"
      end
      
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

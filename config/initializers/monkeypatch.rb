# Monkeypatching of Rails default classes
#
# Used to coerce the Rails classes into conforming to the markup
# guidelines for malmo.se

module ActionView
  module Helpers
    #module AssetTagHelper
    #  private

    #  # *MONKEYPATCH*
    #  #
    #  # <tt>actionpack-3.2.13/lib/action_view/helpers/asset_tag_helper:</tt>
    #  #
    #  # Patch to ignore relative_url_root when using an asset host
    #  def compute_public_path(source, dir, ext = nil, include_host = true)
    #    has_request = @controller.respond_to?(:request)

    #    source_ext = File.extname(source)[1..-1]
    #    if ext && (source_ext.blank? || (ext != source_ext && File.exist?(File.join(ASSETS_DIR, dir, "#{source}.#{ext}"))))
    #      source += ".#{ext}"
    #    end

    #    unless source =~ %r{^[-a-z]+://}
    #      source = "/#{dir}/#{source}" unless source[0] == ?/

    #      source = rewrite_asset_path(source)

    #      # MONKEYPATCH: Added check on asset_host
    #      if has_request && include_host && ActionController::Base.asset_host.blank?
    #        unless source =~ %r{^#{ActionController::Base.relative_url_root}/}
    #          source = "#{ActionController::Base.relative_url_root}#{source}"
    #        end
    #      end
    #    end

    #    if include_host && source !~ %r{^[-a-z]+://}
    #      host = compute_asset_host(source)

    #      if has_request && !host.blank? && host !~ %r{^[-a-z]+://}
    #        host = "#{@controller.request.protocol}#{host}"
    #      end

    #      "#{host}#{source}"
    #    else
    #      source
    #    end
    #  end
    #end

    class InstanceTag
      private
      # *MONKEYPATCH*
      #
      # <tt>actionpack-3.2.13/lib/action_view/helpers/form_helper:1222</tt>
      #
      # Overrides the method generating the DOM ID for a field
      def tag_id
        # MONKEYPATCH: Added kp- prefix
        "kp-#{sanitized_object_name}-#{sanitized_method_name}"
      end
      # *MONKEYPATCH*
      #
      # <tt>actionpack-3.2.13/lib/action_view/helpers/form_helper.rb:1226</tt>
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
      # <tt>actionpack-3.2.13/lib/action_view/helpers/date_helper.rb:950</tt>
      #
      # Overrides the DOM ID generator for date/time selectors
      def input_id_from_type(type)
        id = input_name_from_type(type).gsub(/([\[\(])|(\]\[)/, '_').gsub(/[\]\)]/, '')
        id = @options[:namespace] + '_' + id if @options[:namespace]

        # MONKEYPATCH: Added kp- prefix
        "kp-#{id}"
      end
    end

    class FormBuilder
      # *MONKEYPATCH*
      #
      # <tt>actionpack-3.2.13/lib/action_view/helpers/form_helper.rb:1369</tt>
      #
      # Overrides the method generating the submit button, prefixing the submit button's DOM ID.
      def submit(value=nil, options={})
        value, options = nil, value if value.is_a?(Hash)
        value ||= submit_default_value
        # MONKEYPATCH: Added kp- prefix to id
        @template.submit_tag(value, options.reverse_merge(:id => "kp-#{object_name}_submit"))
      end
    end

    module FormTagHelper
      # *MONKEYPATCH*
      #
      # <tt>actionpack-3.2.13/lib/action_view/helpers/form_tag_helper:377</tt>
      #
      # Overrides the DOM ID generation, prefixing the ID
      def radio_button_tag(name, value, checked = false, options = {})
        sanitized_name  = name.to_s.gsub(']','').gsub(/[^-a-zA-Z0-9:.]/, "_")
        sanitized_value = value.to_s.gsub(']','').gsub(/[^-a-zA-Z0-9:.]/, "_")

        # MONKEYPATCH: Added kp- prefix to id
        html_options = { "type" => "radio", "name" => name, "id" => "kp-#{sanitized_name}_#{sanitized_value}", "value" =>     value }.update(options.stringify_keys)
        html_options["checked"] = "checked" if checked
        tag :input, html_options
      end

      # *MONKEYPATCH*
      #
      # <tt>actionpack-3.2.13/lib/action_view/helpers/form_tag_helper:680</tt>
      #
      # Overrides the DOM ID generation to prefix the ID
      def sanitize_to_id(name)
        # MONKEYPATCH: Added kp- prefix
        "kp-" + name.to_s.gsub(']','').gsub(/[^-a-zA-Z0-9:.]/, "_")
      end
    end
  end
end

module ActionController
  module RecordIdentifier
    # *MONKEYPATCH*
    #
    # <tt>actionpack-3.2.13/lib/action_controller/record_identifier.rb:42</tt>
    #
    # Overrides the DOM class generator to prefix the class
    def dom_class(record_or_class, prefix = nil)
      singular = ActiveModel::Naming.param_key(record_or_class)
      # MONKEYPATCH: Added kp-prefix
      prefix ? "kp-#{prefix}#{JOIN}#{singular}" : "kp-#{singular}"
    end
  end
end

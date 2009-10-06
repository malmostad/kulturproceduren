module KPWillPaginate
  class LinkRenderer < WillPaginate::LinkRenderer

    attr_accessor :gap_marker

    def initialize
      @gap_marker = '<li><span class="gap">&hellip;</span></li>'
    end

    # Process it! This method returns the complete HTML string which contains
    # pagination links. Feel free to subclass LinkRenderer and change this
    # method as you see fit.
    def to_html
      links = @options[:page_links] ? windowed_links : []
      # previous/next buttons
      links.unshift page_link_or_span(@collection.previous_page, 'disabled prev_page', @options[:previous_label])
      links.push    page_link_or_span(@collection.next_page,     'disabled next_page', @options[:next_label])

      html = links.join(@options[:separator])
      @options[:container] ? @template.content_tag(:ul, html, html_attributes) : html
    end


    protected

    def page_link(page, text, attributes = {})
      @template.content_tag(:li, @template.link_to(text, url_for(page), attributes))
    end

    def page_span(page, text, attributes = {})
      @template.content_tag(:li, @template.content_tag(:span, text, attributes))
    end
  end
end

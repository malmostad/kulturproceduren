module KPWillPaginate

  # LinkRenderer for WillPaginate that implements the markup guidelines for malmo.se.
  #
  # Renders the pagination links using a list.
  class LinkRenderer < WillPaginate::LinkRenderer

    attr_accessor :gap_marker

    # Redefines the gap marker to be a list entry
    def initialize
      @gap_marker = '<li><span class="gap">&hellip;</span></li>'
    end

    # Renders the actual list of paging links.
    #
    # The method is essentially copied from WillPaginate::LinkRenderer with a <tt>ul</tt> tag added
    def to_html
      links = @options[:page_links] ? windowed_links : []
      # previous/next buttons
      links.unshift page_link_or_span(@collection.previous_page, 'disabled prev_page', @options[:previous_label])
      links.push    page_link_or_span(@collection.next_page,     'disabled next_page', @options[:next_label])

      html = links.join(@options[:separator])
      @options[:container] ? @template.content_tag(:ul, html, html_attributes) : html
    end


    protected

    # Adds a <tt>li</tt>-tag surrounding the pagination link
    def page_link(page, text, attributes = {})
      @template.content_tag(:li, @template.link_to(text, url_for(page), attributes))
    end

    # Adds a <tt>li</tt>-tag surrounding the page indicator
    def page_span(page, text, attributes = {})
      @template.content_tag(:li, @template.content_tag(:span, text, attributes))
    end
  end
end

# -*- encoding : utf-8 -*-
module KPWillPaginate

  # LinkRenderer for WillPaginate that implements the markup guidelines for malmo.se.
  #
  # Renders the pagination links using a list.
  class LinkRenderer < WillPaginate::ActionView::LinkRenderer

    protected

    # The container is a list
    def html_container(html)
      tag(:ul, html, container_attributes)
    end

    # Redefines the gap marker to be a list entry
    def gap
      '<li><span class="gap">&hellip;</span></li>'
    end

    # Wrap page numbers in list entries
    def page_number(page)
      unless page == current_page
        tag(:li, link(page, page, rel: rel_value(page)))
      else
        tag(:li, tag(:span, page, class: 'current'))
      end
    end

    # Wrap previous/next links in list entries
    def previous_or_next_page(page, text, classname)
      if page
        tag(:li, link(text, page, class: classname))
      else
        tag(:li, tag(:span, text, class: classname + ' disabled'))
      end
    end
  end
end

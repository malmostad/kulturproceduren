# Bootstrap will_paginate and set default settings
require "will_paginate"

WillPaginate::ViewHelpers.pagination_options[:previous_label] = 'Föregående'
WillPaginate::ViewHelpers.pagination_options[:next_label] = 'Nästa'
WillPaginate::ViewHelpers.pagination_options[:renderer] = 'KPWillPaginate::LinkRenderer'

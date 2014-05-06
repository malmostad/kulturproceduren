# Dummy controller for Ajax ping.
#
# Used to prevent the session from timing out, escpecially
# when run via a proxy portlet.
class PingController < ApplicationController
  def ping
    render text: "pong", content_type: "text/plain"
  end
end

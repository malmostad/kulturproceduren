# Helpers for mailers
module MailerHelper
  # Helper for generating links in outgoing mails
  def mail_url(url)
    APP_CONFIG[:kp_external_link] + "?goto=" + CGI.escape(url)
  end
end

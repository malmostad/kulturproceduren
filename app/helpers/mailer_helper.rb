# Helpers for mailers
module MailerHelper
  # Helper for generating links in outgoing mails
  def mail_url(url)
    #Goto fungerar ej i den nya Assets4 designen. Pekar istället om till en vanlig url så SiteVision kan redirecta till nya kp-hosten.
    APP_CONFIG[:kp_external_link] + url
  end
end

class ApplicationMailer < ActionMailer::Base

  def mailer_logger
    @@mailer_logger ||= Logger.new("#{Rails.root}/log/email.log")
  end

  def mail_from_app(recipients, subject_app, dateOfSend=Time.zone.now)

    mailer_logger.info "Sent mail. Subject [#{subject_app}]. To: [#{recipients}]"

    mail(
        to: recipients,
        date: dateOfSend,
        subject: subject_app
    )
  end

end
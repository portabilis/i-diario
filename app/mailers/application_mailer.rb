class ApplicationMailer < ActionMailer::Base
  default from: "sample@#{ActionMailer::Base.smtp_settings[:domain]}"
end

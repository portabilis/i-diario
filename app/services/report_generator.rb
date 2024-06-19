# frozen_string_literal: true

class ReportGenerator
  def self.call(html, driver: :chrome)
    RestClient.post(Rails.application.secrets.report_html_url, {
      html: html,
      driver: driver
    }, {
      Authorization: "Bearer #{Rails.application.secrets.resport_html_secret_key}"
    })
  end
end

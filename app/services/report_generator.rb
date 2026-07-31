# frozen_string_literal: true

class ReportGenerator
  # Timeouts para o serviço externo de geração (HTML -> PDF). Sem eles, um serviço
  # lento penduraria o worker HTTP indefinidamente e poderia esgotar o pool.
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 30

  def self.call(html, driver: :chrome)
    RestClient::Request.execute(
      method: :post,
      url: Rails.application.secrets.report_html_url,
      payload: { html: html, driver: driver },
      headers: { Authorization: "Bearer #{Rails.application.secrets.report_html_secret_key}" },
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    )
  end
end

# frozen_string_literal: true

class ReportGenerator
  # Timeouts para o serviço externo de geração (HTML -> PDF). Sem eles, um serviço
  # lento penduraria o worker HTTP indefinidamente e poderia esgotar o pool.
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 30

  # Acima deste tamanho o corpo vai comprimido: corpo grande estoura os limites de
  # transporte do serviço de renderização (413/502). 1 MB é margem de segurança,
  # não o limite exato do serviço.
  GZIP_THRESHOLD_BYTES = 1.megabyte

  def self.call(html, driver: :chrome)
    payload, encoding_headers = build_request(html: html, driver: driver)

    RestClient::Request.execute(
      method: :post,
      url: Rails.application.secrets.report_html_url,
      payload: payload,
      headers: encoding_headers.merge(Authorization: "Bearer #{Rails.application.secrets.report_html_secret_key}"),
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    )
  end

  # O serviço só descomprime corpo JSON: o header Content-Encoding sem o corpo
  # efetivamente comprimido (ou o inverso) devolve 400. Por isso o corpo troca de
  # formato no limiar — form-encoded abaixo, JSON comprimido acima — e os headers
  # de codificação vêm junto do payload correspondente.
  #
  # O limiar mede o corpo serializado, não o HTML: o escaping do JSON infla o
  # payload em ~48%, então medir só o HTML deixaria passar sem comprimir corpos
  # que já estouram o limite de transporte.
  private_class_method def self.build_request(params)
    body = params.to_json

    return [params, {}] if body.bytesize < GZIP_THRESHOLD_BYTES

    [
      ActiveSupport::Gzip.compress(body),
      { content_type: :json, 'Content-Encoding' => 'gzip' }
    ]
  end
end

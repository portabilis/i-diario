# Renderiza o PEI em PDF (layout de impressão + serviço externo de geração) e envia
# inline. Compartilhado entre o controller do plano e o de versões.
#
# A geração depende de um serviço HTTP externo: falha (timeout/5xx/conexão) ou retorno
# que não seja um PDF válido não podem virar 500 cru — logam com contexto (id/entity) e
# voltam com aviso amigável.
module RendersIepPdf
  extend ActiveSupport::Concern

  # Exceções esperadas do serviço externo (RestClient cobre timeouts e status non-2xx).
  PDF_SERVICE_ERRORS = [RestClient::Exception, SocketError, Errno::ECONNREFUSED].freeze

  private

  def send_iep_pdf(filename:, log_context:)
    html = render_to_string(
      template: 'individualized_educational_plans/pdf',
      layout: 'pdf_individualized_educational_plan',
      formats: [:html]
    )

    body = ReportGenerator.call(html).body

    # RestClient só levanta em non-2xx; um 200 com corpo que não é PDF (HTML de erro,
    # vazio, truncado) seria enviado como se fosse válido.
    return handle_pdf_failure(log_context, 'resposta não é um PDF válido') unless body.to_s.start_with?('%PDF')

    send_data body, filename: filename, type: 'application/pdf', disposition: 'inline'
  rescue *PDF_SERVICE_ERRORS => e
    handle_pdf_failure(log_context, e.message)
  end

  def handle_pdf_failure(log_context, message)
    Rails.logger.error("PEI PDF - falha ao gerar (#{log_context}): #{message}")
    Honeybadger.notify("PEI PDF generation failed", context: { detail: log_context, message: message })

    redirect_back fallback_location: individualized_educational_plans_path,
                  alert: t('individualized_educational_plans.pdf.generation_failed')
  end
end

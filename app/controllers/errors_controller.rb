class ErrorsController < ApplicationController
  layout 'error_page'

  def show
    status_code = params[:code] || 500

    text = case status_code.to_i
           when Rack::Utils::SYMBOL_TO_STATUS_CODE[:not_found]
             t('http_codes.not_found')
           when Rack::Utils::SYMBOL_TO_STATUS_CODE[:unprocessable_entity]
             t('http_codes.unprocessable_entity')
           else
             t('http_codes.internal_server_error')
           end

    @page_title = "#{text} (#{status_code})"

    render status_code.to_s
  end
end

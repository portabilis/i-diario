class ErrorsController < ApplicationController
  def not_found
    page_title(t('http_codes.not_found'), Rack::Utils::SYMBOL_TO_STATUS_CODE[:not_found])
  end

  def unprocessable_entity
    page_title(t('http_codes.unprocessable_entity'), Rack::Utils::SYMBOL_TO_STATUS_CODE[:unprocessable_entity])
  end

  def internal_server_error
    page_title(t('http_codes.internal_server_error'), Rack::Utils::SYMBOL_TO_STATUS_CODE[:internal_server_error])
  end

  def page_title(text, status_code)
    @page_title = "#{text} (#{status_code})"
  end
end

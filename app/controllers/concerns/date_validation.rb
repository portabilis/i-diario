# Os campos de data dos formulários são de texto livre e aceitam datas inexistentes
# ("31/06/2026"), que fazem String#to_date levantar Date::Error. Como Date::Error herda de
# ArgumentError, o rescue cobre também datas em formato irreconhecível.
module DateValidation
  extend ActiveSupport::Concern

  private

  def valid_date?(date_string)
    parse_date(date_string).present?
  end

  def parse_date(date_string)
    return if date_string.blank?

    date_string.to_date
  rescue ArgumentError
    nil
  end
end

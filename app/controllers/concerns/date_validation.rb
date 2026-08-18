# Os campos de data dos formulários são de texto livre e aceitam datas que não existem no
# calendário ("31/06/2026"), fazendo String#to_date levantar Date::Error. A captura é por
# ArgumentError, superclasse portável de Date::Error, que cobre também formato ilegível.
#
# Um parâmetro pode chegar como array ou hash ("?data[]=x"), e nesse caso o to_date
# levantaria NoMethodError, que escaparia do rescue: por isso a checagem de que o valor
# responde a to_date antes de converter.
module DateValidation
  extend ActiveSupport::Concern

  private

  def valid_date?(value)
    parse_date(value).present?
  end

  def parse_date(value)
    return if value.blank? || !value.respond_to?(:to_date)

    value.to_date
  rescue ArgumentError
    nil
  end
end

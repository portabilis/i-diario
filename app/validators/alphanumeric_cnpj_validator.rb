# frozen_string_literal: true

# Validador de CNPJ que aceita o formato alfanumerico da Receita Federal
# (valido a partir de jul/2026) e mantem compatibilidade com CNPJs numericos.
#
# Uso:
#   validates :cnpj, alphanumeric_cnpj: true, allow_blank: true
#
# A logica de validacao (formato + digitos verificadores) fica centralizada em
# CnpjAlphanumeric.
class AlphanumericCnpjValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if CnpjAlphanumeric.valid?(value)

    record.errors.add(attribute, options[:message] || :incorrect_format)
  end
end

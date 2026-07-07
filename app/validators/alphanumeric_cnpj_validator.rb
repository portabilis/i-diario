# frozen_string_literal: true

# Validador de CNPJ que aceita o formato alfanumérico da Receita Federal
# (válido a partir de jul/2026) e mantém compatibilidade com CNPJs numéricos.
#
# Uso:
#   validates :cnpj, alphanumeric_cnpj: true, allow_blank: true
#
# A lógica de validação (formato + dígitos verificadores) fica centralizada em
# CnpjAlphanumeric.
class AlphanumericCnpjValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if CnpjAlphanumeric.valid?(value)

    record.errors.add(attribute, options[:message] || :incorrect_format)
  end
end

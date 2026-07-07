# frozen_string_literal: true

# Validação e cálculo de dígitos verificadores de CNPJ no formato alfanumérico
# da Receita Federal (IN RFB 2.119/2022, alterada pela IN RFB 2.229/2024),
# válido a partir de julho/2026 para novas inscrições.
#
# Regras do formato:
# - 14 posições, máscara XX.XXX.XXX/XXXX-DV.
# - As 12 primeiras posições (raiz + ordem) aceitam letras MAIÚSCULAS A-Z e
#   dígitos 0-9. Os 2 dígitos verificadores (DV) permanecem sempre numéricos.
# - CNPJs puramente numéricos antigos continuam válidos (coexistência): o mesmo
#   algoritmo cobre os dois formatos, pois para dígitos `char.ord - 48` retorna
#   o próprio valor numérico.
#
# Cálculo do DV: módulo 11 com pesos cíclicos de 2 a 9 da direita para a
# esquerda; o valor de cada posição é `char.ord - 48` (0-9 => 0-9, A-Z => 17-42).
module CnpjAlphanumeric
  module_function

  BASE_LENGTH = 12

  # Pesos cíclicos (2..9 da direita p/ esquerda) para cada DV, da esquerda p/ direita.
  # O 2º DV cobre uma posição a mais (base + 1º DV), por isso o peso 6 prefixado.
  FIRST_DV_WEIGHTS = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2].freeze
  SECOND_DV_WEIGHTS = [6, *FIRST_DV_WEIGHTS].freeze

  FORMAT_REGEX = /\A[0-9A-Z]{12}[0-9]{2}\z/.freeze

  # Remove máscara/pontuação e normaliza para maiúsculas. Retorna "" para nil.
  def normalize(value)
    return '' if value.nil?

    value.to_s.gsub(/[^0-9A-Za-z]/, '').upcase
  end

  # true para CNPJ numérico OU alfanumérico válido (formato + dígitos verificadores).
  def valid?(value)
    cnpj = normalize(value)

    return false unless cnpj.match?(FORMAT_REGEX) # ancora exatamente 14 posições

    base = cnpj[0, BASE_LENGTH]
    return false if base.chars.uniq.length == 1 # rejeita base com todos os caracteres iguais

    calculate_dv(base) == cnpj[BASE_LENGTH, 2]
  end

  # Calcula os 2 dígitos verificadores de uma base de 12 posições.
  def calculate_dv(base)
    first = mod11(base, FIRST_DV_WEIGHTS)
    second = mod11(base + first.to_s, SECOND_DV_WEIGHTS)

    "#{first}#{second}"
  end

  def mod11(chars, weights)
    sum = chars.chars.each_with_index.sum { |char, index| (char.ord - 48) * weights[index] }
    remainder = sum % 11

    # Regra do módulo 11: resto 0 ou 1 => dígito 0; caso contrário, 11 - resto.
    remainder < 2 ? 0 : 11 - remainder
  end

  private_class_method :mod11
end

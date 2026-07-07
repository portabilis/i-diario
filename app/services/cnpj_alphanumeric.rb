# frozen_string_literal: true

# Validacao e calculo de digitos verificadores de CNPJ no formato alfanumerico
# da Receita Federal (IN RFB 2.119/2022, alterada pela IN RFB 2.229/2024),
# valido a partir de julho/2026 para novas inscricoes.
#
# Regras do formato:
# - 14 posicoes, mascara XX.XXX.XXX/XXXX-DV.
# - As 12 primeiras posicoes (raiz + ordem) aceitam letras MAIUSCULAS A-Z e
#   digitos 0-9. Os 2 digitos verificadores (DV) permanecem sempre numericos.
# - CNPJs puramente numericos antigos continuam validos (coexistencia): o mesmo
#   algoritmo cobre os dois formatos, pois para digitos `char.ord - 48` retorna
#   o proprio valor numerico.
#
# Calculo do DV: modulo 11 com pesos ciclicos de 2 a 9 da direita para a
# esquerda; o valor de cada posicao e `char.ord - 48` (0-9 => 0-9, A-Z => 17-42).
module CnpjAlphanumeric
  module_function

  BASE_LENGTH = 12

  # Pesos ciclicos (2..9 da direita p/ esquerda) para cada DV, da esquerda p/ direita.
  # O 2o DV cobre uma posicao a mais (base + 1o DV), por isso o peso 6 prefixado.
  FIRST_DV_WEIGHTS = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2].freeze
  SECOND_DV_WEIGHTS = [6, *FIRST_DV_WEIGHTS].freeze

  FORMAT_REGEX = /\A[0-9A-Z]{12}[0-9]{2}\z/.freeze

  # Remove mascara/pontuacao e normaliza para maiusculas. Retorna "" para nil.
  def normalize(value)
    return '' if value.nil?

    value.to_s.gsub(/[^0-9A-Za-z]/, '').upcase
  end

  # true para CNPJ numerico OU alfanumerico valido (formato + digitos verificadores).
  def valid?(value)
    cnpj = normalize(value)

    return false unless cnpj.match?(FORMAT_REGEX) # ancora exatamente 14 posicoes

    base = cnpj[0, BASE_LENGTH]
    return false if base.chars.uniq.length == 1 # rejeita base com todos os caracteres iguais

    calculate_dv(base) == cnpj[BASE_LENGTH, 2]
  end

  # Calcula os 2 digitos verificadores de uma base de 12 posicoes.
  def calculate_dv(base)
    first = mod11(base, FIRST_DV_WEIGHTS)
    second = mod11(base + first.to_s, SECOND_DV_WEIGHTS)

    "#{first}#{second}"
  end

  def mod11(chars, weights)
    sum = chars.chars.each_with_index.sum { |char, index| (char.ord - 48) * weights[index] }
    remainder = sum % 11

    # Regra do modulo 11: resto 0 ou 1 => digito 0; caso contrario, 11 - resto.
    remainder < 2 ? 0 : 11 - remainder
  end

  private_class_method :mod11
end

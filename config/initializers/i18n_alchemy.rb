ActiveSupport.on_load(:active_record) do
  include I18n::Alchemy
end

# "31/06/2026" tem formato válido, mas a data não existe. A gem só confere o formato, então
# a data passa e quebra ao virar objeto Date — ainda na atribuição do atributo, antes de
# qualquer validação do model rodar, derrubando a requisição.
#
# Conferindo a data antes, o campo fica vazio e o model acusa o erro normalmente.
#
# A conferência é da data em si, e não um rescue da exceção: assim, erro de outra origem
# continua subindo e chegando ao Honeybadger.
#
# Só o DateParser é tratado. Time.utc(2026, 6, 31) não quebra — vira 01/07 —, então campos
# de data e hora seguem sem proteção contra data inexistente.
module I18nAlchemyInvalidDateFallback
  def build_object(parsed_date)
    year, month, day = parsed_date.values_at(:year, :mon, :mday)

    return if year && month && day && !Date.valid_date?(year, month, day)

    super
  end
end

# O prepend é no singleton porque os parsers da gem usam `extend self` e são chamados como
# métodos de módulo.
I18n::Alchemy::DateParser.singleton_class.prepend(I18nAlchemyInvalidDateFallback)

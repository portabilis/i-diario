ActiveSupport.on_load(:active_record) do
  include I18n::Alchemy
end

# A gem confere o FORMATO da data informada, mas não se ela existe no calendário: para
# "31/06/2026" o Date._strptime devolve dia 31 e mês 6, e a construção do objeto logo em
# seguida levanta Date::Error. Isso acontece dentro do assign_attributes, antes de qualquer
# validação do model rodar, e derruba a requisição inteira.
#
# Devolvendo nil, o atributo chega vazio ao ActiveRecord e o model acusa o campo do mesmo
# jeito que já faz para data em branco. Date::Error herda de ArgumentError, que é também o
# que o Time.utc do TimeParser levanta.
module I18nAlchemyInvalidDateFallback
  def build_object(parsed_date)
    super
  rescue ArgumentError
    nil
  end
end

# O prepend é no singleton porque os parsers da gem usam `extend self` e são chamados como
# métodos de módulo.
I18n::Alchemy::DateParser.singleton_class.prepend(I18nAlchemyInvalidDateFallback)
I18n::Alchemy::TimeParser.singleton_class.prepend(I18nAlchemyInvalidDateFallback)

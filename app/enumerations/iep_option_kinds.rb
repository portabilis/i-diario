class IepOptionKinds < EnumerateIt::Base
  # Grupos de multi-select do PEI. Valores casam com o seed (SeedIepOptions).
  associate_values(
    communication_profile: 0,        # Perfil de comunicação (seção 2)
    social_interaction_profile: 1,   # Perfil de interação social e comportamental (seção 2)
    autonomy: 2,                     # Autonomia e vida diária (seção 2)
    accompaniment: 3,                # Realiza acompanhamento com (seção 3)
    support_type: 4,                 # Tipos de suporte (seção 3)
    instructional_accommodation: 5,  # Acomodações Instrucionais (seção 4)
    environmental_accommodation: 6,  # Acomodações Ambientais (seção 4)
    assessment_accommodation: 7      # Acomodações Avaliação (seção 4)
  )

  sort_by :none

  # Resolve o valor inteiro a partir do símbolo/string do kind
  # (o value_for do EnumerateIt 1.3.1 não cobre este caso).
  # Retorna nil para kind desconhecido (evita NameError quando vem de params).
  def self.value_of(kind)
    return kind if kind.is_a?(Integer)

    const_name = kind.to_s.upcase
    const_defined?(const_name) ? const_get(const_name) : nil
  end
end

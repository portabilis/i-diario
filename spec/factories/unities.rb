FactoryGirl.define do
  factory :unity do
    association :author, factory: :user

    sequence(:api_code, &:to_s)
    # O banco da entidade de teste persiste entre execuções e o .unique do Faker é por processo:
    # o sufixo aleatório evita colidir com a unidade que uma execução anterior deixou gravada.
    name { "#{Faker::University.unique.name} #{SecureRandom.hex(4)}" }
    unit_type UnitTypes::SCHOOL_UNIT
  end
end

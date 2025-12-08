FactoryGirl.define do
  factory :system_notification do
    title { "Notificação do Sistema" }
    description { "Descrição da notificação" }
    generic true
    
    trait :with_source do
      association :source, factory: :user
      generic false
    end
  end
end
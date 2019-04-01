FactoryGirl.define do
  factory :daily_note do
    avaliation

    factory :current_daily_note do
      association :avaliation, factory: :current_avaliation
    end
  end
end

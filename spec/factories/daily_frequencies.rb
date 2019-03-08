FactoryGirl.define do
  factory :daily_frequency do
    frequency_date { Time.zone.today }

    unity
    classroom
    discipline
    class_number 1
    period 1
    association :school_calendar, factory: :school_calendar_with_one_step

    trait :current do
      frequency_date { Time.zone.today }
      association :classroom, factory: [:classroom, :current]
      association :school_calendar, factory: :current_school_calendar_with_one_step
    end

    trait :without_discipline do
      discipline nil
      class_number nil
    end

    trait :by_discipline do
      association :classroom, factory: [:classroom, :current, :by_discipline]
    end
  end
end

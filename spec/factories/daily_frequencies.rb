FactoryGirl.define do
  factory :daily_frequency do
    unity
    classroom
    discipline
    association :school_calendar, factory: :school_calendar_with_one_step

    frequency_date { Date.current }
    class_number { rand(1..5) }
    period { Periods.to_a.sample[1] }

    trait :current do
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

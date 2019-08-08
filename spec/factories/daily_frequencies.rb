FactoryGirl.define do
  factory :daily_frequency do
    discipline
    association :classroom, factory: [:classroom, :with_classroom_semester_steps]

    unity { classroom.unity }
    school_calendar { classroom.calendar.try(:school_calendar) || create(:school_calendar, :current) }

    frequency_date { Date.current }
    class_number { rand(1..5) }
    period { Periods.to_a.sample[1] }

    trait :current do
      classroom
      association :school_calendar, factory: :current_school_calendar_with_one_step
    end

    trait :without_discipline do
      discipline nil
      class_number nil
    end

    trait :by_discipline do
      association :classroom, factory: [:classroom, :by_discipline]
    end
  end
end

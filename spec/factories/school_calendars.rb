FactoryGirl.define do
  factory :school_calendar do
    unity

    year Date.current.year
    number_of_classes { rand(1..5) }

    trait :with_one_step do
      after(:build) do |school_calendar|
        school_calendar.steps.build(
          attributes_for(
            :school_calendar_step,
            step_number: 1,
            start_at: "01/01/#{school_calendar.year}",
            end_at: "31/12/#{school_calendar.year}",
            start_date_for_posting: "01/01/#{school_calendar.year}",
            end_date_for_posting: "31/12/#{school_calendar.year}"
          )
        )
      end
    end

    trait :with_trimester_steps do
      after(:build) do |school_calendar|
        (1..3).each do |trimester|
          school_calendar.steps.build(
            attributes_for(
              :school_calendar_step,
              step_number: trimester,
              start_at: Date.new(school_calendar.year, (trimester * 3 - 2), 10),
              end_at: Date.new(school_calendar.year, (trimester * 3), 20),
              start_date_for_posting: Date.new(school_calendar.year, (trimester * 3 - 2), 10),
              end_date_for_posting: Date.new(school_calendar.year, (trimester * 3), 1).end_of_month
            )
          )
        end
      end
    end

    trait :with_semester_steps do
      after(:build) do |school_calendar|
        (1..2).each do |semester|
          school_calendar.steps.build(
            attributes_for(
              :school_calendar_step,
              step_number: semester,
              start_at: Date.new(school_calendar.year, (semester * 6 - 5), 1),
              end_at: Date.new(school_calendar.year, (semester * 6), 1).end_of_month,
              start_date_for_posting: Date.new(school_calendar.year, (semester * 6 - 5), 1),
              end_date_for_posting: Date.new(school_calendar.year, (semester * 6), 1).end_of_month
            )
          )
        end
      end
    end
  end
end

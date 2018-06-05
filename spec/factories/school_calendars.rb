FactoryGirl.define do
  factory :school_calendar do
    year 2020
    number_of_classes 5

    unity

    factory :school_calendar_with_one_step do
      after(:build) do |school_calendar|
        school_calendar.steps
          .build(attributes_for(
                  :school_calendar_step,
                  start_at: "01/01/#{school_calendar.year}",
                  end_at: "31/12/#{school_calendar.year}",
                  start_date_for_posting: "01/01/#{school_calendar.year}",
                  end_date_for_posting: "31/12/#{school_calendar.year}"
                )
          )
      end

      factory :current_school_calendar_with_one_step do
        year { Time.zone.today.year }
      end
    end

    trait :school_calendar_with_semester_steps do
      after(:build) do |school_calendar|
        (1..2).each do |semester|
          school_calendar.steps
            .build(attributes_for(
                    :school_calendar_step,
                    start_at: Date.new(school_calendar.year, (semester * 6 - 5), 1),
                    end_at: Date.new(school_calendar.year, (semester * 6), 1).end_of_month,
                    start_date_for_posting: Date.new(school_calendar.year, (semester * 6 - 5), 1),
                    end_date_for_posting: Date.new(school_calendar.year, (semester * 6), 1).end_of_month
                  )
            )
        end
      end
    end

    trait :current do
      year { Time.zone.today.year }
    end
  end
end

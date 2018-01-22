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
  end
end

FactoryGirl.define do
  factory :school_calendar do
    year 2020
    number_of_classes 5

    unity

    after(:build) do |school_calendar|
      school_calendar.steps.build(attributes_for(:school_calendar_step, start_at: "01/01/#{school_calendar.year}", end_at: "30/06/#{school_calendar.year}", start_date_for_posting: "10/06/#{school_calendar.year}", end_date_for_posting: "30/06/#{school_calendar.year}"))
    end
  end
end

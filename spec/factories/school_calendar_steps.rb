FactoryGirl.define do
  factory :school_calendar_step do
    association :school_calendar, factory: :school_calendar_with_one_step

    step_number 1
    start_at '01/01/2020'
    end_at '30/06/2020'
    start_date_for_posting '10/06/2020'
    end_date_for_posting '30/06/2020'
  end
end

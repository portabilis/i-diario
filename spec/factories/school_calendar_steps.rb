FactoryGirl.define do
  factory :school_calendar_step do
    school_calendar

    step_number 1
    start_at { Date.current.beginning_of_year }
    end_at { Date.current.end_of_year }
    start_date_for_posting { Date.current.beginning_of_year }
    end_date_for_posting { Date.current.end_of_year }
  end
end

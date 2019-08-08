FactoryGirl.define do
  factory :school_calendar_classroom_step do
    school_calendar_classroom

    step_number 1
    start_at { Date.current }
    end_at { Date.current + 30 }
    start_date_for_posting { Date.current }
    end_date_for_posting { Date.current + 30 }
  end
end

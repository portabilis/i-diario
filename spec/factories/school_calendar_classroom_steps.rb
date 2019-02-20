FactoryGirl.define do
  factory :school_calendar_classroom_step do
    step_number 1
    start_at { Time.zone.today }
    end_at   { Time.zone.today + 30 }
    start_date_for_posting { Time.zone.today }
    end_date_for_posting   { Time.zone.today + 30 }

    school_calendar_classroom
  end
end

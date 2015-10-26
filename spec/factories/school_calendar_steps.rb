FactoryGirl.define do
  factory :school_calendar_step do
    start_at '01/01/2020'
    end_at   '30/06/2020'
    start_date_for_posting   '10/06/2020'
    end_date_for_posting   '30/06/2020'

    school_calendar
  end
end

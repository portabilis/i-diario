FactoryGirl.define do
  factory :lesson_plan do
    start_at '30/06/2020'
    end_at '30/07/2020'
    contents {[FactoryGirl.create(:content)]}

    unity
  	classroom
  	association :school_calendar, factory: :school_calendar_with_one_step
  end
end

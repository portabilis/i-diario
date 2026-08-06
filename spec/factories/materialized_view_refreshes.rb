FactoryGirl.define do
  factory :materialized_view_refresh do
    view_name { MvwFrequencyBySchoolClassroomTeacher.table_name }
    refreshed_at { Time.current }
  end
end

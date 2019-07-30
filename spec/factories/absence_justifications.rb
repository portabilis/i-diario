FactoryGirl.define do
  factory :absence_justification do
    teacher
    student

    teacher_id { teacher.id }
    absence_date { Date.current }
    absence_date_end { Date.current + 1 }
    justification { Faker::Lorem.sentence }
  end
end

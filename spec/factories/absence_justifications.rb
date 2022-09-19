FactoryGirl.define do
  factory :absence_justification do
    teacher
    classroom
    students do
      create_list(:student, 1)
    end

    disciplines do
      create_list(:discipline, 1)
    end

    classroom_id { classroom.id }

    teacher_id { teacher.id }
    absence_date { Date.current }
    absence_date_end { Date.current + 1 }
    justification { Faker::Lorem.sentence }
  end
end

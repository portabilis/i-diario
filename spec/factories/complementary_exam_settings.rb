FactoryGirl.define do
  factory :complementary_exam_setting do
    description { Faker::Lorem.sentence }
    initials { Faker::Lorem.characters(2).upcase }
    affected_score { AffectedScoreTypes::STEP_AVERAGE }
    calculation_type { CalculationTypes::SUM }
    maximum_score { rand(1..10) }
    number_of_decimal_places { rand(0..2) }
    year { Date.current.year }

    transient do
      classroom nil
      discipline nil
    end

    trait :with_two_grades do
      grades { create_list(:grade, 2) }
    end

    trait :with_teacher_discipline_classroom do
      before(:create) do |complementary_exam_setting, evaluator|
        teacher = create(:teacher)
        discipline = evaluator.discipline || create(:discipline)
        (evaluator.grades || complementary_exam_setting.grades).each do |grade|
          classroom_grade = create(:classrooms_grade, grade_id: grade)
          classroom = classroom_grade.classroom

          create(
            :teacher_discipline_classroom,
            classroom: classroom,
            discipline: discipline,
            teacher: teacher
          )
        end
      end
    end
  end
end

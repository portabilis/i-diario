require 'rails_helper'

RSpec.describe StudentEnrollmentsRetriever, type: :service do
  context 'when the params are correct' do
  end

  context 'when the params are incorrect' do
  end

  context 'when student_enrollments has active students' do
    it 'should return student_enrollments with search_type: :by_date' do
      classroom_grade = create(:classrooms_grade)
      discipline = create(:discipline)
      student_enrollment_classrooms = create_list(:student_enrollment_classroom, 3, classrooms_grade: classroom_grade)
      student_enrollments = student_enrollment_classrooms.map(&:student_enrollment)

      list_student_enrollments = StudentEnrollmentsRetriever.call(
        search_type: :by_date,
        classroom: classroom_grade.classroom_id,
        discipline: discipline,
        date: '2018-02-02'
      )

      expect(list_student_enrollments.to_a).to eq(student_enrollments)
    end
    it 'should return student_enrollments with search_type: :by_year'
    it 'should return student_enrollments with search_type: :by_range_date'
  end
end
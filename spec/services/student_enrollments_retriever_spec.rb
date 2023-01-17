require 'rails_helper'

RSpec.describe StudentEnrollmentsRetriever, type: :service do
  let(:classroom_grade) { create(:classrooms_grade) }
  let(:discipline) { create(:discipline) }
  let(:student_enrollment_classrooms) { create_list(:student_enrollment_classroom, 3, classrooms_grade: classroom_grade) }
  let(:student_enrollments) { student_enrollment_classrooms.map(&:student_enrollment) }

  before do
    classroom_grade
    discipline
    student_enrollment_classrooms
    student_enrollments
  end

  context 'when the params are correct' do
    subject(:list_student_enrollments) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date,
        classroom: classroom_grade.classroom_id,
        discipline: discipline,
        date: '2018-02-02'
      )
    }

    it 'should return list of student_enrollments' do
      expect(list_student_enrollments.size).to eq(3)
    end

    it 'should ensure that params are valid' do
      expect(list_student_enrollments).to be_truthy
    end

  end

  context 'when the params are incorrect' do
    it 'should return empty list of student_enrollments' do
      classroom_invalid = create(:classroom)
      discipline_invalid = create(:classroom)

      list_student_enrollments = StudentEnrollmentsRetriever.call(
        search_type: 'invalid',
        classroom: classroom_invalid,
        discipline: discipline_invalid,
        date: '0000-00-00'
      )

      expect(list_student_enrollments).to be_empty
    end

    it 'should return ArgumentError to missing params @date' do
      expect {
        StudentEnrollmentsRetriever.call(
          search_type: :by_date,
          classroom: classroom_grade.classroom_id,
          discipline: discipline
        )
      }.to raise_error(ArgumentError)
    end

    it 'should return nil for blank params' do
      expect(
        StudentEnrollmentsRetriever.call(
          search_type: '',
          classroom: '',
          discipline: '',
          date: '2018-02-02'
        )
      ).to be_nil
    end
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
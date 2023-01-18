require 'rails_helper'

RSpec.describe StudentEnrollmentsRetriever, type: :service do
  let(:classroom_grade) { create(:classrooms_grade) }
  let(:discipline) { create(:discipline) }
  let(:student_enrollment_classrooms) {
    create_list(
      :student_enrollment_classroom,
      3,
      classrooms_grade: classroom_grade,
      joined_at: '2023-02-02',
      left_at: '2023-12-12'
    )
  }
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
        date: '2023-02-02'
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

      expect(
        StudentEnrollmentsRetriever.call(
          search_type: 'invalid',
          classroom: classroom_invalid,
          discipline: discipline_invalid,
          date: '0000-00-00'
        )
      ).to be_empty
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
          date: '2023-02-02'
        )
      ).to be_nil
    end
  end

  context 'when there are active and inactive student_enrollments' do
    let(:student_enrollments_inactive) { create_list(:student_enrollment, 3, active: IeducarBooleanState::INACTIVE) }

    subject(:list_student_enrollments) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date,
        classroom: classroom_grade.classroom_id,
        discipline: discipline,
        date: '2023-02-02'
      )
    }

    it 'should not return in the list student_enrollments inactives' do
      expect(list_student_enrollments).not_to eq(student_enrollments_inactive)
    end

    it 'should return in the list student_enrollments actives' do
      expect(list_student_enrollments).to eq(student_enrollments)
    end

  end

  context 'when there are enrollment_classrooms liked to student_enrollments' do
    let(:list_classrooms) { create_list(:classroom, 3) }

    subject(:list_student_enrollments) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date,
        classroom: [list_classrooms, classroom_grade.classroom_id],
        discipline: discipline,
        date: '2023-02-02'
      )
    }

    it 'should return student_enrollments liked to classrooms' do
      expect(list_student_enrollments).to eq(student_enrollments)
    end

    it 'should not return student_enrollments without linked classrooms' do
      enrollment_without_classroom = create_list(:student_enrollment, 3)

      expect(list_student_enrollments).not_to eq(enrollment_without_classroom)
    end
  end

  context 'when there are student_enrollment_dependence liked to student_enrollments' do
    let(:student_enrollment_dependence) {
      create(
        :student_enrollment_dependence,
        discipline: discipline,
        student_enrollment: student_enrollments.last
      )
    }

    subject(:list_student_enrollments) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date,
        classroom: classroom_grade.classroom_id,
        discipline: discipline,
        date: '2023-02-02'
      )
    }

    it 'should return student_enrollment in dependence on the discipline' do
      expect(list_student_enrollments.last).to eq(student_enrollments.last)
    end

    it 'should return student_enrollments with and without dependence on the discipline' do
      expect(list_student_enrollments).to eq(student_enrollments)
    end

    it 'should not return student_enrollments in dependence on another discipline' do
      student_enrollment_dependence = create_list(:student_enrollment_dependence, 3)
      student_enrollments_ids = list_student_enrollments.pluck(:id)

      expect(student_enrollments_ids).not_to include(student_enrollment_dependence.map(&:student_enrollment_id))
    end

  end

  context 'when student_enrollments has enrollment_classrooms actives' do
    # it 'should return list of student_enrollments with enrollment_classrooms in date' do
    #
    #   list_student_enrollments = StudentEnrollmentsRetriever.call(
    #     search_type: :by_date,
    #     classroom: classroom_grade.classroom_id,
    #     discipline: discipline,
    #     date: '2018-02-02'
    #   )
    #
    #   expect(list_student_enrollments.size).to eq(3)
    # end

    # it 'should return list of student_enrollments with enrollment_classrooms out date' do
    #
    #   list_student_enrollments = StudentEnrollmentsRetriever.call(
    #     search_type: :by_date,
    #     classroom: classroom_grade.classroom_id,
    #     discipline: discipline,
    #     date: '2018-02-02'
    #   )
    #
    #   expect(list_student_enrollments.size).to eq(3)
    # end

    it 'should return student_enrollments with search_type: :by_year'
    it 'should return student_enrollments with search_type: :by_range_date'
  end
end
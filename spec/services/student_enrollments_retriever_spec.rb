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
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        date: '2023-02-02'
      )
    }

    it 'should return list of student_enrollments' do
      expect(list_student_enrollments.size).to eq(3)
    end

    it 'should ensure that params are valid' do
      expect(list_student_enrollments).to be_truthy
    end

    it 'should return a student_enrollment relation' do
      expect(list_student_enrollments.class).to eq(StudentEnrollment::ActiveRecord_Relation)
    end

  end

  context 'when the params are incorrect' do

    it 'should return ArgumentError to missing params @date' do
      expect {
        StudentEnrollmentsRetriever.call(
          search_type: :by_date,
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline
        )
      }.to raise_error(ArgumentError, 'Should define date argument on search by date')
    end

    it 'should return ArgumentError to missing params @start_at or @end_at' do
      expect {
        StudentEnrollmentsRetriever.call(
          search_type: :by_date_range,
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline,
          date: '2023-02-02'
        )
      }.to raise_error(ArgumentError, 'Should define @start_at or @end_at argument on search by date_range')
    end

    it 'should return empty list of student_enrollments not linked to classroom and discipline' do
      classroom_invalid = create(:classroom)
      discipline_invalid = create(:discipline)

      expect(
        StudentEnrollmentsRetriever.call(
          search_type: :by_date,
          classrooms: classroom_invalid,
          disciplines: discipline_invalid,
          date: '2023-02-02'
        )
      ).to be_empty
    end

    it 'should return nil for blank params' do
      expect(
        StudentEnrollmentsRetriever.call(
          search_type: '',
          classrooms: '',
          disciplines: ''
        )
      ).to be_nil
    end
  end

  context 'when there are active and inactive student_enrollments' do
    let(:student_enrollments_inactive) { create_list(:student_enrollment, 3, active: IeducarBooleanState::INACTIVE) }

    subject(:list_student_enrollments) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        date: '2023-02-02'
      )
    }

    it 'should not return in the list student_enrollments inactives' do
      expect(list_student_enrollments).not_to include(student_enrollments_inactive.first)
    end

    it 'should return in the list student_enrollments actives' do
      expect(list_student_enrollments).to include(student_enrollments.first)
    end

  end

  context 'when there are enrollment_classrooms liked with student_enrollments' do
    let(:list_classrooms) { create_list(:classroom, 3) }

    subject(:list_student_enrollments) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date,
        classrooms: [list_classrooms, classroom_grade.classroom_id],
        disciplines: discipline,
        date: '2023-02-02'
      )
    }

    it 'should return student_enrollments liked to classrooms' do
      expect(list_student_enrollments).to include(student_enrollments.first)
    end

    it 'should not return student_enrollments without linked classrooms' do
      enrollment_without_classroom = create(:student_enrollment)

      expect(list_student_enrollments).not_to include(enrollment_without_classroom)
    end
  end

  context 'when there are student_enrollment_dependence liked with student_enrollments' do
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
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        date: '2023-02-02'
      )
    }

    it 'should return student_enrollment in dependence on the discipline' do
      expect(list_student_enrollments).to include(student_enrollments.last)
    end

    it 'should return student_enrollments with and without dependence on the discipline' do
      expect(list_student_enrollments).to include(student_enrollments.first)
    end

    it 'should not return student_enrollments in dependence on another discipline' do
      student_enrollment_dependence = create_list(:student_enrollment_dependence, 3)
      student_enrollments_ids = list_student_enrollments.pluck(:id)

      expect(student_enrollments_ids).not_to include(student_enrollment_dependence.map(&:student_enrollment_id))
    end
  end

  context 'when to send @date to search student_enrollments' do
    let(:enrollment_classrooms) {
      create_list(
        :student_enrollment_classroom,
        3,
        classrooms_grade: classroom_grade,
        joined_at: '2022-02-02',
        left_at: '2022-12-12'
      )
    }
    let(:enrollments_out_date) { enrollment_classrooms.map(&:student_enrollment) }

    subject(:list_student_enrollments) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        date: '2023-03-02'
      )
    }

    it 'should return list of student_enrollments on @date' do
      expect(list_student_enrollments).to include(student_enrollments.first)
    end


    it 'should not return list of student_enrollments out of @date' do
      expect(list_student_enrollments).not_to include(enrollments_out_date)
    end
  end

  context 'when to send date range to search student_enrollments' do
    let(:enrollment_classrooms) {
      create_list(
        :student_enrollment_classroom,
        3,
        classrooms_grade: classroom_grade,
        joined_at: '2022-02-02',
        left_at: '2022-12-12'
      )
    }
    let(:enrollments_out_date) { enrollment_classrooms.map(&:student_enrollment) }

    subject(:list_student_enrollments) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date_range,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        start_at: '2023-03-02',
        end_at: '2023-11-02'
      )
    }

    it 'should return list of student_enrollments on date range' do
      expect(list_student_enrollments).to include(student_enrollments.last)
    end


    it 'should not return list of student_enrollments out of date range' do
      expect(list_student_enrollments).not_to eq(enrollments_out_date)
    end
  end

  context 'when to send year to search student_enrollments' do
    let(:classroom) { create(:classroom, year: 2022) }
    let(:enrollment_classrooms) {
      create_list(
        :student_enrollment_classroom,
        3,
        classroom_code: classroom.api_code
      )
    }
    let(:enrollments_out_date) { enrollment_classrooms.map(&:student_enrollment) }

    subject(:list_student_enrollments) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_year,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        year: '2017'
      )
    }

    it 'should return list of student_enrollments on @year' do
      expect(list_student_enrollments).to include(student_enrollments.first)
    end


    it 'should not return list of student_enrollments out of @year' do
      expect(list_student_enrollments).not_to include(enrollments_out_date.first)
    end
  end

  context 'when show_inactive checkbox is enabled' do
    before do
      GeneralConfiguration.current.update(show_inactive_enrollments: true)
    end

    subject(:student_enrollment_retriever) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date_range,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        start_at: '2023-03-03',
        end_at: '2023-06-03'
      )
    }

    it 'should return return student_enrollment with attending status' do
      student_enrollments_list = create_student_enrollments

      expect(student_enrollment_retriever).to include(student_enrollments_list.first, student_enrollments_list.last)
    end
  end

  context 'when show_inactive checkbox is not enabled' do
    subject(:student_enrollment_retriever) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date_range,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        start_at: '2023-03-03',
        end_at: '2023-06-03'
      )
    }

    it 'should not return student_enrollment with transferred status' do
      student_enrollment_transferred = create_student_enrollments

      expect(student_enrollment_retriever).not_to include(student_enrollment_transferred.first)
    end
  end

  context 'when grade params exist' do
    let(:classroom_grade_without_liked) { create_list(:classrooms_grade, 3) }

    it 'should return empty list of student_enrollments without linked to @grade' do
      expect(
        StudentEnrollmentsRetriever.call(
          search_type: :by_date,
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline,
          date: '2023-03-03',
          grade: classroom_grade_without_liked.first
        )
      ).to be_empty
    end

    it 'should return list of student_enrollments linked to @grade' do
      expect(
        StudentEnrollmentsRetriever.call(
          search_type: :by_date,
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline,
          date: '2023-03-03',
          grade: classroom_grade.grade_id
        )
      ).to include(student_enrollments.first)
    end
  end

  context 'when include_date_range params exist' do
    it '' do

    end
  end
end

def create_student_enrollments
  student_enrollment_list = []

  student = create(:student)
  enrollment_inactive = create(:student_enrollment, student: student, status: 4)
  create(
    :student_enrollment_classroom,
    student_enrollment: enrollment_inactive,
    classrooms_grade: classroom_grade,
    joined_at: '2023-02-02',
    left_at: '2023-03-12',
    show_as_inactive_when_not_in_date: true
  )

  student_enrollment_list << enrollment_inactive

  enrollment_active = create(:student_enrollment, student: student, status: 3)
  create(
    :student_enrollment_classroom,
    student_enrollment: enrollment_active,
    classrooms_grade: classroom_grade,
    joined_at: '2023-05-02'
  )

  student_enrollment_list << enrollment_active
end

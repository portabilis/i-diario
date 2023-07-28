require 'rails_helper'

RSpec.describe StudentEnrollmentClassroomsRetriever, type: :service do
  let(:exam_rule_both) { create(:exam_rule, score_type: ScoreTypes::NUMERIC_AND_CONCEPT) }
  let(:classroom) { create(:classroom, period: Periods::VESPERTINE, year: '2023') }
  let(:classroom_grade) { create(:classrooms_grade, classroom: classroom, exam_rule: exam_rule_both) }
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

  before do
    classroom
    classroom_grade
    discipline
    student_enrollment_classrooms
  end

  context 'when the params are correct' do
    subject(:list_enrollment_classrooms) {
      StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        date: '2023-02-02'
      )
    }

    it 'should return list of student_enrollment_classrooms' do
      expect(list_enrollment_classrooms.size).to eq(3)
    end

    it 'should ensure that params are valid' do
      expect(list_enrollment_classrooms).to be_truthy
    end

    it 'should return a student_enrollment_classrooms relation' do
      expect(list_enrollment_classrooms.class).to eq(StudentEnrollmentClassroom::ActiveRecord_Relation)
    end

  end

  context 'when the params are incorrect' do
    it 'should return ArgumentError to missing params @date' do
      expect {
        StudentEnrollmentClassroomsRetriever.call(
          search_type: :by_date,
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline
        )
      }.to raise_error(ArgumentError, 'Should define date argument on search by date')
    end

    it 'should return ArgumentError to missing params @start_at or @end_at' do
      expect {
        StudentEnrollmentClassroomsRetriever.call(
          search_type: :by_date_range,
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline,
          date: '2023-02-02'
        )
      }.to raise_error(ArgumentError, 'Should define start_at or end_at argument on search by date_range')
    end

    it 'should return empty list of student_enrollment_classrooms not linked to classroom and discipline' do
      classroom_invalid = create(:classroom)
      discipline_invalid = create(:discipline)

      expect(
        StudentEnrollmentClassroomsRetriever.call(
          search_type: :by_date,
          classrooms: classroom_invalid,
          disciplines: discipline_invalid,
          date: '2023-02-02'
        )
      ).to be_empty
    end

    it 'should return nil for blank params' do
      expect(
        StudentEnrollmentClassroomsRetriever.call(
          search_type: '',
          classrooms: '',
          disciplines: ''
        )
      ).to be_nil
    end
  end

  context 'when there are student_enrollment_classrooms linked to active and inactive student_enrollments' do
    let(:student_enrollment_inactive) { create(:student_enrollment, active: IeducarBooleanState::INACTIVE) }
    let(:student_enrollment_classroom_inactive) {
      create(
        :student_enrollment_classroom,
        student_enrollment: student_enrollment_inactive
      )
    }

    subject(:list_student_enrollment_classrooms) {
      StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        date: '2023-02-02'
      )
    }

    it 'should return in the list student_enrollments actives' do
      expect(list_student_enrollment_classrooms).to include(student_enrollment_classrooms.first)
    end

    it 'should not return in the list student_enrollments inactives' do
      expect(list_student_enrollment_classrooms).not_to eq(student_enrollment_classroom_inactive)
    end
  end

  context 'when there are many classrooms in params' do
    let(:another_classroom) { create(:classroom) }

    subject(:list_student_enrollment_classrooms) {
      StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date,
        classrooms: [another_classroom, classroom_grade.classroom_id],
        disciplines: discipline,
        date: '2023-02-02'
      )
    }

    it 'should return student_enrollment_classrooms liked to classrooms' do
      expect(list_student_enrollment_classrooms).to include(student_enrollment_classrooms.first)
    end

    it 'should not return student_enrollment_classrooms without linked classrooms' do
      another_student_enrollment_classroom = create(:student_enrollment_classroom)

      expect(list_student_enrollment_classrooms).not_to include(another_student_enrollment_classroom)
    end
  end

  context 'when there are students with dependence on the disciplines' do
    let(:student_enrollment_dependence) {
      create(
        :student_enrollment_dependence,
        discipline: discipline,
        student_enrollment: student_enrollment_classrooms.last.student_enrollment
      )
    }

    subject(:list_student_enrollment_classrooms) {
      StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        date: '2023-02-02'
      )
    }

    it 'should return student_enrollment_classrooms in dependence on the discipline' do
      expect(list_student_enrollment_classrooms).to include(student_enrollment_classrooms.last)
    end

    it 'should return student_enrollment_classrooms without dependence on the discipline' do
      expect(list_student_enrollment_classrooms).to include(student_enrollment_classrooms.first)
    end

    it 'should not return student_enrollments in dependence on another discipline' do
      another_student_enrollment_dependence = create(:student_enrollment_dependence)
      another_student_enrollment_classroom = create(
        :student_enrollment_classroom,
        student_enrollment: another_student_enrollment_dependence.student_enrollment
      )

      expect(list_student_enrollment_classrooms).not_to contain_exactly(
        another_student_enrollment_classroom
      )
    end
  end

  context 'when there is a date to search for student_enrollment_classrooms' do
    let(:student_enrollment_classrooms_out_date) {
      create_list(
        :student_enrollment_classroom,
        3,
        classrooms_grade: classroom_grade,
        joined_at: '2022-02-02',
        left_at: '2022-12-12'
      )
    }

    subject(:list_student_enrollment_classrooms) {
      StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        date: '2023-03-02'
      )
    }

    it 'should return list of student_enrollment_classrooms on date' do
      expect(list_student_enrollment_classrooms).to include(student_enrollment_classrooms.first)
    end

    it 'should not return list of student_enrollment_classrooms out of date' do
      expect(list_student_enrollment_classrooms).not_to include(student_enrollment_classrooms_out_date)
    end
  end

  context 'when there is a range of dates to search for student_enrollment_classrooms' do
    let(:student_enrollment_classrooms_out_date) {
      create_list(
        :student_enrollment_classroom,
        3,
        classrooms_grade: classroom_grade,
        joined_at: '2022-02-02',
        left_at: '2022-12-12'
      )
    }

    subject(:list_student_enrollment_classrooms) {
      StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date_range,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        start_at: '2023-03-02',
        end_at: '2023-11-02'
      )
    }

    it 'should return list of student_enrollment_classrooms on date range' do
      expect(list_student_enrollment_classrooms).to include(student_enrollment_classrooms.last)
    end


    it 'should not return list of student_enrollment_classrooms out of date range' do
      expect(list_student_enrollment_classrooms).not_to eq(student_enrollment_classrooms_out_date)
    end
  end

  context 'when there is a year to search for student_enrollment_classrooms' do
    let(:classroom_with_year) { create(:classroom, year: 2022) }
    let(:classrooms_grade_with_year) { create(:classrooms_grade, classroom: classroom_with_year) }
    let(:student_enrollment_classrooms_year_2022) {
      create_list(
        :student_enrollment_classroom,
        3,
        classrooms_grade: classrooms_grade_with_year
      )
    }

    it 'should return list of student_enrollment_classrooms on year 2022' do
      expect(
        StudentEnrollmentClassroomsRetriever.call(
          search_type: :by_year,
          classrooms: classroom_with_year,
          disciplines: discipline,
          year: '2022'
        )
      ).to include(student_enrollment_classrooms_year_2022.first)
    end

    it 'should not return list of student_enrollment_classrooms on year 2022' do
      expect(
        StudentEnrollmentsRetriever.call(
          search_type: :by_year,
          classrooms: classroom,
          disciplines: discipline,
          year: '2022'
        )
      ).not_to include(student_enrollment_classrooms_year_2022.first)
    end
  end

  context 'when show_inactive checkbox is enabled in settings' do
    before do
      GeneralConfiguration.current.update(show_inactive_enrollments: true)
    end

    subject(:list_student_enrollment_classrooms) {
      StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date_range,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        start_at: '2023-03-03',
        end_at: '2023-06-03'
      )
    }

    it 'should return student_enrollment_classrooms with all status' do
      create_student_enrollment_classrooms_with_status
      expect(list_student_enrollment_classrooms).to include(
        @enrollment_classroom_inactive,
        @enrollment_classroom_active
      )
    end
  end

  context 'when show_inactive checkbox is not enabled in settings' do
    subject(:list_student_enrollment_classrooms) {
      StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date_range,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        start_at: '2023-03-03',
        end_at: '2023-06-03'
      )
    }

    it 'should return student_enrollment_classrooms with studying status' do
      create_student_enrollment_classrooms_with_status
      expect(list_student_enrollment_classrooms).to include(@enrollment_classroom_active)
    end

    it 'should not return student_enrollment_classrooms with transferred status' do
      create_student_enrollment_classrooms_with_status
      expect(list_student_enrollment_classrooms).not_to include(@enrollment_classroom_inactive)
    end
  end

  context 'when grade params exist' do
    let(:classroom_grade_without_liked) { create(:classrooms_grade) }

    it 'should return empty list of student_enrollment_classrooms without linked to grade' do
      expect(
        StudentEnrollmentClassroomsRetriever.call(
          search_type: :by_date,
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline,
          date: '2023-03-03',
          grade: classroom_grade_without_liked
        )
      ).to be_empty
    end

    it 'should return list of student_enrollment_classrooms linked to grade' do
      expect(
        StudentEnrollmentClassroomsRetriever.call(
          search_type: :by_date,
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline,
          date: '2023-03-03',
          grade: classroom_grade.grade_id
        )
      ).to include(student_enrollment_classrooms.first)
    end
  end

  context 'when include_date_range params exist' do
    let(:student_enrollment_classrooms) { create_student_enrollment_classrooms }

    it 'should return student_enrollment_classrooms with joined_at dates after start_at' do
      expect(
        StudentEnrollmentClassroomsRetriever.call(
          search_type: :by_date_range,
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline,
          start_at: '2023-03-03',
          end_at: '2023-06-03',
          include_date_range: true
        )
      ).to include(student_enrollment_classrooms.first, student_enrollment_classrooms.last)
    end

    it 'should return student_enrollment_classrooms with joined_at dates before @start_at' do
      expect(
        StudentEnrollmentClassroomsRetriever.call(
          search_type: :by_date_range,
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline,
          start_at: '2023-04-20',
          end_at: '2023-12-03',
          include_date_range: true
        )
      ).to include(student_enrollment_classrooms.last)
    end
  end

  context 'when period params exist' do
    let(:classroom_vespertine) { create(:classroom, period: Periods::FULL) }
    let(:classroom_grade_all_period) { create(:classrooms_grade, classroom: classroom_vespertine) }
    let(:enrollment_classroom) {
      create(
        :student_enrollment_classroom,
        classrooms_grade: classroom_grade_all_period,
        joined_at: '2023-03-03'
      )
    }

    it 'should return student_enrollment_classroom attending the full period' do
      expect(
        StudentEnrollmentClassroomsRetriever.call(
          classrooms: classroom_grade_all_period.classroom_id,
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          period: Periods::FULL
        )
      ).to include(enrollment_classroom)
    end

    it 'should not return student_enrollment_classroom attending the full period' do
      expect(
        StudentEnrollmentClassroomsRetriever.call(
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          period: Periods::FULL
        )
      ).to include(student_enrollment_classrooms.first)
    end
  end

  context 'when score_type params exist' do
    it 'should return list of student_enrollment_classrooms with score_type NUMERIC_AND_CONCEPT' do
      expect(
        StudentEnrollmentClassroomsRetriever.call(
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          score_type: StudentEnrollmentScoreTypeFilters::BOTH
        )
      ).to include(student_enrollment_classrooms.first)
    end

    it 'should return list of student_enrollment_classrooms score_type numeric' do
      exam_rule_numeric = create(:exam_rule, score_type: ScoreTypes::NUMERIC)
      classroom_grade_with_numeric = create(:classrooms_grade, exam_rule: exam_rule_numeric)
      student_enrollment_classroom = create(
        :student_enrollment_classroom,
        joined_at: '2023-03-03',
        classrooms_grade: classroom_grade_with_numeric
      )

      expect(
        StudentEnrollmentClassroomsRetriever.call(
          classrooms: [classroom_grade.classroom_id, classroom_grade_with_numeric.classroom_id],
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          score_type: StudentEnrollmentScoreTypeFilters::NUMERIC
        )
      ).to contain_exactly(student_enrollment_classroom)
    end

    it 'should return list of student_enrollment_classrooms with score_type concept' do
      exam_rule_concept = create(:exam_rule, score_type: ScoreTypes::CONCEPT)
      classroom_grade_with_concept = create(:classrooms_grade, exam_rule: exam_rule_concept)
      student_enrollment_classroom = create(
        :student_enrollment_classroom,
        joined_at: '2023-03-03',
        classrooms_grade: classroom_grade_with_concept
      )

      expect(
        StudentEnrollmentClassroomsRetriever.call(
          classrooms: [classroom_grade.classroom_id, classroom_grade_with_concept.classroom_id],
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          score_type: StudentEnrollmentScoreTypeFilters::CONCEPT
        )
      ).to contain_exactly(student_enrollment_classroom)
    end

    it 'should return list of student_enrollments with score_type both if given nil' do
      expect(
        StudentEnrollmentClassroomsRetriever.call(
          classrooms: classroom_grade.classroom_id,
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          score_type: nil
        )
      ).to include(student_enrollment_classrooms.first)
    end
  end

  context 'when with_recovery_note_in_step params exist'
end

def create_student_enrollment_classrooms_with_status
  student = create(:student)
  enrollment_inactive = create(:student_enrollment, student: student, status: 4)
  @enrollment_classroom_inactive = create(
    :student_enrollment_classroom,
    student_enrollment: enrollment_inactive,
    classrooms_grade: classroom_grade,
    joined_at: '2023-04-04',
    left_at: '2023-03-12',
    show_as_inactive_when_not_in_date: true
  )

  enrollment_active = create(:student_enrollment, student: student, status: 3)
  @enrollment_classroom_active = create(
    :student_enrollment_classroom,
    student_enrollment: enrollment_active,
    classrooms_grade: classroom_grade,
    joined_at: '2023-05-02'
  )
end

def create_student_enrollment_classrooms
  student_enrollment_classrooms = []

  enrollment_classroom_first = create(
    :student_enrollment_classroom,
    classrooms_grade: classroom_grade,
    joined_at: '2023-04-04'
  )
  student_enrollment_classrooms << enrollment_classroom_first

  enrollment_classroom_second = create(
    :student_enrollment_classroom,
    classrooms_grade: classroom_grade,
    joined_at: '2023-05-04'
  )
  student_enrollment_classrooms << enrollment_classroom_second
end

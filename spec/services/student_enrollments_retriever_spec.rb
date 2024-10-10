require 'rails_helper'

RSpec.describe StudentEnrollmentsRetriever, type: :service do
  let(:exam_rule_both) { create(:exam_rule, score_type: ScoreTypes::NUMERIC_AND_CONCEPT) }
  let!(:classroom) { create(:classroom, period: Periods::VESPERTINE, year: '2023') }
  let!(:classroom_grade) { create(:classrooms_grade, classroom: classroom, exam_rule: exam_rule_both) }
  let!(:discipline) { create(:discipline) }
  let!(:student_enrollment_classrooms) {
    create_list(
      :student_enrollment_classroom,
      3,
      classrooms_grade: classroom_grade,
      joined_at: '2023-02-02',
      left_at: '2023-12-12'
    )
  }
  let!(:student_enrollments) { student_enrollment_classrooms.map(&:student_enrollment) }

  context 'when the params are correct' do
    subject(:list_student_enrollments) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date,
        classrooms: classroom_grade.classroom,
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
          classrooms: classroom_grade.classroom,
          disciplines: discipline
        )
      }.to raise_error(ArgumentError, 'Should define date argument on search by date')
    end

    it 'should return ArgumentError to missing params @start_at or @end_at' do
      expect {
        StudentEnrollmentsRetriever.call(
          search_type: :by_date_range,
          classrooms: classroom_grade.classroom,
          disciplines: discipline,
          date: '2023-02-02'
        )
      }.to raise_error(ArgumentError, 'Should define start_at or end_at argument on search by date_range')
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
        classrooms: classroom_grade.classroom,
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
        classrooms: [list_classrooms, classroom_grade.classroom].flatten,
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
        classrooms: classroom_grade.classroom,
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

      student_enrollments_ids = list_student_enrollments.map(&:id)

      expect(student_enrollments_ids).not_to include(student_enrollment_dependence.map(&:student_enrollment_id))
    end
  end

  context 'when to send date to search student_enrollments' do
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
        classrooms: classroom_grade.classroom,
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
        classrooms: classroom_grade.classroom,
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
    let(:classroom_with_year) { create(:classroom, year: 2022) }
    let(:classrooms_grade_with_year) { create(:classrooms_grade, classroom: classroom_with_year) }
    let(:enrollment_classrooms) {
      create_list(
        :student_enrollment_classroom,
        3,
        classrooms_grade: classrooms_grade_with_year
      )
    }
    let(:enrollments_year_2022) { enrollment_classrooms.map(&:student_enrollment) }

    before do
      classroom_with_year
      classrooms_grade_with_year
      enrollment_classrooms
      enrollments_year_2022
    end

    it 'should return list of student_enrollments on year 2022' do
      expect(
        StudentEnrollmentsRetriever.call(
          search_type: :by_year,
          classrooms: classroom_with_year,
          disciplines: discipline,
          year: '2022'
        )
      ).to include(enrollments_year_2022.first)
    end

    it 'should not return list of student_enrollments on year 2022' do
      expect(
        StudentEnrollmentsRetriever.call(
          search_type: :by_year,
          classrooms: classroom,
          disciplines: discipline,
          year: '2022'
        )
      ).not_to include(enrollments_year_2022.first)
    end
  end

  context 'when show_inactive checkbox is enabled' do
    before do
      GeneralConfiguration.current.update(show_inactive_enrollments: true)
    end

    subject(:student_enrollment_retriever) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date_range,
        classrooms: classroom_grade.classroom,
        disciplines: discipline,
        start_at: '2023-03-03',
        end_at: '2023-06-03'
      )
    }

    it 'Is expected return more student_enrollment with for the same student' do
      student_enrollments_list = create_student_enrollments_with_students_duplicated

      expect(student_enrollment_retriever).to include(student_enrollments_list.first, student_enrollments_list.last)
    end
  end

  context 'when show_inactive checkbox is not enabled' do
    subject(:student_enrollment_retriever) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date_range,
        classrooms: classroom_grade.classroom,
        disciplines: discipline,
        start_at: '2023-03-03',
        end_at: '2023-06-03'
      )
    }

    it 'Is expected to return only one active student_enrollment per student' do
      student_enrollment_uniq = create_student_enrollments_with_students_duplicated

      expect(student_enrollment_retriever).not_to include(student_enrollment_uniq.first)
      expect(student_enrollment_retriever).to include(student_enrollment_uniq.last)
    end
  end

  context 'when grade params exist' do
    let(:classroom_grade_without_liked) { create_list(:classrooms_grade, 3) }

    it 'should return empty list of student_enrollments without linked to @grade' do
      expect(
        StudentEnrollmentsRetriever.call(
          search_type: :by_date,
          classrooms: classroom_grade.classroom,
          disciplines: discipline,
          date: '2023-03-03',
          grades: classroom_grade_without_liked.first
        )
      ).to be_empty
    end

    it 'should return list of student_enrollments linked to @grade' do
      expect(
        StudentEnrollmentsRetriever.call(
          search_type: :by_date,
          classrooms: classroom_grade.classroom,
          disciplines: discipline,
          date: '2023-03-03',
          grades: classroom_grade.grade_id
        )
      ).to include(student_enrollments.first)
    end
  end

  context 'when include_date_range params exist' do
    let!(:student_enrollments_list) { create_list_student_enrollments }

    it 'should return student_enrollments with joined_at dates after @start_at' do
      student_enrollments = StudentEnrollmentsRetriever.call(
        search_type: :by_date_range,
        classrooms: classroom_grade.classroom,
        disciplines: discipline,
        start_at: '2023-03-03',
        end_at: '2023-06-03',
        include_date_range: true
      )

      date_of_joined = StudentEnrollmentClassroom.where(
        student_enrollment_id: [student_enrollments.map(&:id)]
      ).map(&:joined_at).uniq

      date_of_joined.each do |dates|
        expect(dates.to_date).to be > '2023-03-03'.to_date
      end
    end

    it 'should return student_enrollments with joined_at dates before @start_at' do
      expect(
        StudentEnrollmentsRetriever.call(
          search_type: :by_date_range,
          classrooms: classroom_grade.classroom,
          disciplines: discipline,
          start_at: '2023-04-20',
          end_at: '2023-12-03',
          include_date_range: true
        )
      ).to include(student_enrollments_list.second)
    end
  end

  context 'when opinion_type params exist' do
    let(:exam_rule) { create(:exam_rule, opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE) }
    let(:classroom_grade_with_exam_rule) { create(:classrooms_grade, exam_rule: exam_rule) }
    let(:enrollment_classroom) {
      create(
        :student_enrollment_classroom,
        classrooms_grade: classroom_grade_with_exam_rule,
        joined_at: '2023-03-03'
      )
    }

    before do
      exam_rule
      classroom_grade_with_exam_rule
      enrollment_classroom
    end

    it 'should return student_enrollment with opinion_type by step and discipline' do
      expect(
        StudentEnrollmentsRetriever.call(
          classrooms: classroom_grade_with_exam_rule.classroom,
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          opinion_type: exam_rule.opinion_type
        )
      ).to include(enrollment_classroom.student_enrollment)
    end

    it 'should not return student_enrollment with opinion_type by step and discipline' do
      expect(
        StudentEnrollmentsRetriever.call(
          classrooms: classroom_grade.classroom,
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          opinion_type: exam_rule.opinion_type
        )
      ).to be_empty
    end
  end

  context 'when period params exist' do
    let(:classroom_vespertine) { create(:classroom, period: Periods::FULL) }
    let(:classroom_grade_with_period) { create(:classrooms_grade, classroom: classroom_vespertine) }
    let(:enrollment_classroom) {
      create(
        :student_enrollment_classroom,
        classrooms_grade: classroom_grade_with_period,
        joined_at: '2023-03-03'
      )
    }

    before do
      classroom_vespertine
      classroom_grade_with_period
      enrollment_classroom
    end

    it 'should return student_enrollment attending the full period' do
      expect(
        StudentEnrollmentsRetriever.call(
          classrooms: classroom_grade_with_period.classroom,
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          period: Periods::FULL
        )
      ).to include(enrollment_classroom.student_enrollment)
    end

    it 'should not return student_enrollment attending the full period' do
      expect(
        StudentEnrollmentsRetriever.call(
          classrooms: classroom_grade.classroom,
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          period: Periods::FULL
        )
      ).to include(student_enrollments.first)
    end
  end

  context 'when score_type params exist' do
    it 'should return list of student_enrollments with score_type NUMERIC_AND_CONCEPT' do
      expect(
        StudentEnrollmentsRetriever.call(
          classrooms: classroom_grade.classroom,
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          score_type: StudentEnrollmentScoreTypeFilters::BOTH
        )
      ).to include(student_enrollments.first)
    end

    it 'should return list of student_enrollments score_type numeric' do
      exam_rule_numeric = create(:exam_rule, score_type: ScoreTypes::NUMERIC)
      classroom_grade_with_numeric = create(:classrooms_grade, exam_rule: exam_rule_numeric)
      enrollment_classrooms = create(
        :student_enrollment_classroom,
        joined_at: '2023-03-03',
        classrooms_grade: classroom_grade_with_numeric
      )

      expect(
        StudentEnrollmentsRetriever.call(
          classrooms: [classroom_grade.classroom, classroom_grade_with_numeric.classroom],
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          score_type: StudentEnrollmentScoreTypeFilters::NUMERIC
        )
      ).to contain_exactly(enrollment_classrooms.student_enrollment)
    end

    it 'should return list of student_enrollments with score_type concept' do
      exam_rule_concept = create(:exam_rule, score_type: ScoreTypes::CONCEPT)
      classroom_grade_with_concept = create(:classrooms_grade, exam_rule: exam_rule_concept)
      enrollment_classrooms = create(
        :student_enrollment_classroom,
        joined_at: '2023-03-03',
        classrooms_grade: classroom_grade_with_concept
      )

      expect(
        StudentEnrollmentsRetriever.call(
          classrooms: [classroom_grade.classroom, classroom_grade_with_concept.classroom],
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          score_type: StudentEnrollmentScoreTypeFilters::CONCEPT
        )
      ).to contain_exactly(enrollment_classrooms.student_enrollment)
    end

    it 'should return list of student_enrollments with score_type both if given nil' do
      expect(
        StudentEnrollmentsRetriever.call(
          classrooms: classroom_grade.classroom,
          disciplines: discipline,
          search_type: :by_date,
          date: '2023-03-10',
          score_type: nil
        )
      ).to include(student_enrollments.first)
    end
  end

  context 'when with_recovery_note_in_step params exist'

  context 'when there are classrooms with multi-grade' do
    let(:grade) { create(:grade) }
    let(:classrooms_grade_with_multi_grade) {
      create(
        :classrooms_grade,
        classroom: classroom_grade.classroom,
        grade: grade
      )
    }
    let(:school_calendar_discipline_grade) {
      create(
        :school_calendar_discipline_grade,
        grade: grade,
        discipline: discipline,
        school_calendar: classroom_grade.classroom.unity.school_calendars.first
      )
    }
    let(:enrollment_classroom) {
      student_enrollment_classrooms.last.update(
        classrooms_grade: classrooms_grade_with_multi_grade
      )
      student_enrollment_classrooms.last
    }

    before do
      classrooms_grade_with_multi_grade
      enrollment_classroom
      school_calendar_discipline_grade
    end

    subject(:student_enrollment_retriever) {
      StudentEnrollmentsRetriever.call(
        search_type: :by_date_range,
        classrooms: classrooms_grade_with_multi_grade.classroom,
        grades: [classroom_grade.grade_id, grade.id],
        disciplines: discipline,
        start_at: '2023-03-03',
        end_at: '2023-06-03'
      )
    }

    it 'overwrites the series as expected and returns student_enrollment from grade-related inclusion' do
      expect(student_enrollment_retriever).to include(enrollment_classroom.student_enrollment)

      included_grades = student_enrollment_retriever
                          .flat_map(&:student_enrollment_classrooms)
                          .flat_map(&:classrooms_grade)
                          .map(&:grade)

      expect(included_grades).to include(grade)
    end


    it 'not returns student_enrollment from grade-related inclusion' do
      expect(student_enrollment_retriever).not_to include(student_enrollments.first)
    end
  end
end

def create_student_enrollments_with_students_duplicated
  student_enrollment_list = []

  student = create(:student)
  enrollment_inactive = create(:student_enrollment, student: student, status: 4)
  create(
    :student_enrollment_classroom,
    student_enrollment: enrollment_inactive,
    classrooms_grade: classroom_grade,
    joined_at: '2023-04-04',
    left_at: '2023-03-12',
    show_as_inactive_when_not_in_date: false
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

def create_list_student_enrollments
  enrollments = create_list(:student_enrollment, 2)

  create(
    :student_enrollment_classroom,
    student_enrollment: enrollments.first,
    classrooms_grade: classroom_grade,
    joined_at: '2023-04-04'
  )

  create(
    :student_enrollment_classroom,
    student_enrollment: enrollments.second,
    classrooms_grade: classroom_grade,
    joined_at: '2023-05-04'
  )

  enrollments
end

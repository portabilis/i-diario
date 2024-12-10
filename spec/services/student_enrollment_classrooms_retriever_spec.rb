require 'rails_helper'

RSpec.describe StudentEnrollmentClassroomsRetriever, type: :service do
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
      left_at: ''
    )
  }

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
      expect{
        StudentEnrollmentClassroomsRetriever.call(
          search_type: '',
          classrooms: '',
          disciplines: ''
        )
      }.to raise_error(ArgumentError, 'Invalid search type')
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

    it 'should return in the list student_enrollment_classrooms actives' do
      actives = list_student_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].student_enrollment.active
      }
      expect(actives).to eq([1, 1, 1])
    end
  end

  context 'when there are many classrooms in params' do
    let(:another_classroom) { create(:classroom) }
    # Cria uma enturmacao para outra turma ficticia
    let(:enrollment_classroom_another) {
      create(
        :student_enrollment_classroom,
        classrooms_grade_id: 55
      )
    }

    subject(:list_student_enrollment_classrooms) {
      StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date,
        classrooms: [another_classroom, classroom_grade.classroom],
        disciplines: discipline,
        date: '2023-02-02'
      )
    }

    it 'should return only student enrollments linked to desired classrooms' do
      liked_classrooms = list_student_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].classrooms_grade.classroom
      }
      expect(liked_classrooms.uniq).to eq([classroom_grade.classroom])
    end
  end

  context 'when there are students with dependence on the disciplines' do
    # Cria dependencia na ultima matricula vinculada a ultima enturmacao
    let!(:student_enrollment_dependence) {
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
      with_dependences = list_student_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].student_enrollment.dependences
      }.flatten
      in_discipline = with_dependences.map(&:discipline)

      expect(with_dependences).to include(student_enrollment_dependence)
      expect(in_discipline).to eq([discipline])
    end

    it 'should return student_enrollment_classrooms with and without dependencies' do
      all_enrollment_classrooms = list_student_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom]
      }
      expect(all_enrollment_classrooms).to match_array(student_enrollment_classrooms)
    end
  end

  context 'when there is a date to search for student_enrollment_classrooms' do
    # Cria enturmacao que ficara enturmada de janeiro a dezembro de 2022
    # Nao deve estar no retorno do servico
    let!(:student_enrollment_classrooms_out_date) {
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

    let!(:on_date) {
      list_student_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].joined_at
      }.uniq
    }

    it 'should return list of student_enrollment_classrooms on date' do
      expect(on_date).to eq(student_enrollment_classrooms.map(&:joined_at).uniq)
    end

    it 'should not return list of student_enrollment_classrooms out of date' do
      expect(on_date).not_to eq(student_enrollment_classrooms_out_date.map(&:joined_at).uniq)
    end
  end

  context 'when there is a range of dates to search for student_enrollment_classrooms' do
    # Cria enturmacao que ficara enturmada de fevereiro a dezembro de 2022
    # Não deve estar no retorno do servico que se refere a 2023
    let!(:student_enrollment_classrooms_out_date) {
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

    let!(:on_date) {
      list_student_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].joined_at
      }.uniq
    }

    it 'should return list of student_enrollment_classrooms on date range' do
      expect(on_date).to eq(student_enrollment_classrooms.map(&:joined_at).uniq)
    end

    it 'should not return list of student_enrollment_classrooms out of date range' do
      expect(on_date).not_to eq(student_enrollment_classrooms_out_date.map(&:joined_at).uniq)
    end
  end

  context 'when there is a year to search for student_enrollment_classrooms' do
    let(:classroom_with_year_2022) { create(:classroom, year: 2022) }
    let(:classrooms_grade_with_year) { create(:classrooms_grade, classroom: classroom_with_year_2022) }
    let!(:student_enrollment_classrooms_year_2022) {
      create_list(
        :student_enrollment_classroom,
        3,
        classrooms_grade: classrooms_grade_with_year
      )
    }
    # Alem de enviarmos o params year e search_type: by_year,
    #   tambem precisamos enviar uma turma com ano de 2022.
    subject(:list_student_enrollment_classrooms) {
      StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_year,
        classrooms: [classroom_with_year_2022, classroom],
        disciplines: discipline,
        year: '2022'
      )
    }

    let!(:years_studied) {
      list_student_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].classrooms_grade.classroom.year
      }.uniq
    }

    it 'should return list of student_enrollment_classrooms on year 2022' do
      expect(years_studied).to eq([classroom_with_year_2022.year])
    end

    it 'should not return list of student_enrollment_classrooms on year *2023*' do
      expect(years_studied).not_to eq([classroom.year])
    end
  end

  describe 'when the client works or not with DATA BASE' do
    before do
      # DATA BASE=(show_as_inactive_when_not_in_date:TRUE)
      create_student_enrollment_classrooms_with_status_and_date_base
    end

    context 'and show_inactive checkbox is enabled in settings' do
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

      let!(:status) {
        list_student_enrollment_classrooms.map { |ec|
          ec[:student_enrollment_classroom].student_enrollment.status
        }.uniq
      }

      it 'should return student_enrollment_classrooms with all status' do
        transferred = @enrollment_classroom_inactive.student_enrollment.status
        studying = @enrollment_classroom_active.student_enrollment.status

        expect(status).to match_array([studying, transferred])
      end
    end

    context 'and show_inactive checkbox is not enabled in settings' do
      before do
        GeneralConfiguration.current.update(show_inactive_enrollments: false)
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

      let!(:status) {
        list_student_enrollment_classrooms.map { |ec|
          ec[:student_enrollment_classroom].student_enrollment.status
        }.uniq
      }

      it 'should return student_enrollment_classrooms with all status' do
        transferred = @enrollment_classroom_inactive.student_enrollment.status
        studying = @enrollment_classroom_active.student_enrollment.status

        expect(status).to match_array([studying, transferred])
      end
    end
  end

  context 'when grade params exist' do
    let!(:classroom_grade_without_liked) { create(:classrooms_grade) }

    it 'should return empty list of student_enrollment_classrooms' do
      list_enrollment_classrooms = StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        date: '2023-03-03',
        grades: classroom_grade_without_liked.grade
      )

      grade_id = list_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].classrooms_grade.grade_id
      }.uniq

      expect(grade_id).to be_empty
    end

    it 'should return list of student_enrollment_classrooms linked to grade' do
      list_enrollment_classrooms = StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        date: '2023-03-03',
        grade: classroom_grade.grade_id
      )

      grade_id = list_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].classrooms_grade.grade_id
      }.uniq

      expect(grade_id).to match_array(classroom_grade.grade_id)
    end
  end

  context 'when include_date_range params exist' do
    let!(:student_enrollment_classrooms) { create_student_enrollment_classrooms }

    it 'should return student_enrollment_classrooms with joined_at dates after @start_at' do
      list_enrollment_classrooms = StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date_range,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        start_at: '2023-03-03',
        end_at: '2023-06-03',
        include_date_range: true
      )

      date_of_joined = list_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].joined_at.to_date
      }.uniq

      date_of_joined.each do |dates|
        expect(dates).to be > '2023-03-03'.to_date
      end
    end
  end

  context 'when period params exist' do
    let(:classroom_full_period) { create(:classroom, period: Periods::FULL) }
    let(:classroom_grade_all_period) { create(:classrooms_grade, classroom: classroom_full_period) }
    let!(:enrollment_classroom) {
      create(
        :student_enrollment_classroom,
        classrooms_grade: classroom_grade_all_period,
        joined_at: '2023-03-03'
      )
    }

    it 'should return student_enrollment_classroom attending the full period' do
      list_enrollment_classrooms = StudentEnrollmentClassroomsRetriever.call(
        classrooms: classroom_grade_all_period.classroom,
        disciplines: discipline,
        search_type: :by_date,
        date: '2023-03-10',
        period: Periods::FULL
      )

      in_period = list_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].classrooms_grade.classroom.period
      }.uniq

      expect(in_period).to eq([classroom_full_period.period])
    end
  end

  context 'when score_type params exist' do
    it 'should return list of student_enrollment_classrooms with score_type NUMERIC_AND_CONCEPT' do
      list_enrollment_classrooms = StudentEnrollmentClassroomsRetriever.call(
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        search_type: :by_date,
        date: '2023-03-10',
        score_type: StudentEnrollmentScoreTypeFilters::BOTH
      )

      list_score_type = list_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].classrooms_grade.exam_rule.score_type
      }.uniq

      score_type = student_enrollment_classrooms.first.classrooms_grade.exam_rule.score_type

      expect(list_score_type).to eq([score_type])
    end

    it 'should return list of student_enrollment_classrooms score_type numeric' do
      exam_rule_numeric = create(:exam_rule, score_type: ScoreTypes::NUMERIC)
      classroom_grade_with_numeric = create(:classrooms_grade, exam_rule: exam_rule_numeric)
      student_enrollment_classroom = create(
        :student_enrollment_classroom,
        joined_at: '2023-03-03',
        classrooms_grade: classroom_grade_with_numeric
      )

      list_enrollment_classrooms = StudentEnrollmentClassroomsRetriever.call(
        classrooms: [classroom_grade.classroom_id, classroom_grade_with_numeric.classroom_id],
        disciplines: discipline,
        search_type: :by_date,
        date: '2023-03-10',
        score_type: StudentEnrollmentScoreTypeFilters::NUMERIC
      )

      list_score_type = list_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].classrooms_grade.exam_rule.score_type
      }.uniq

      expect(list_score_type).to contain_exactly(exam_rule_numeric.score_type)
    end

    it 'should return list of student_enrollment_classrooms with score_type concept' do
      exam_rule_concept = create(:exam_rule, score_type: ScoreTypes::CONCEPT)
      classroom_grade_with_concept = create(:classrooms_grade, exam_rule: exam_rule_concept)
      create(
        :student_enrollment_classroom,
        joined_at: '2023-03-03',
        classrooms_grade: classroom_grade_with_concept
      )

      list_enrollment_classrooms = StudentEnrollmentClassroomsRetriever.call(
        classrooms: [classroom_grade.classroom_id, classroom_grade_with_concept.classroom_id],
        disciplines: discipline,
        search_type: :by_date,
        date: '2023-03-10',
        score_type: StudentEnrollmentScoreTypeFilters::CONCEPT
      )

      list_score_type = list_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].classrooms_grade.exam_rule.score_type
      }.uniq

      expect(list_score_type).to contain_exactly(exam_rule_concept.score_type)
    end

    it 'should return list of student_enrollments with score_type both if given nil' do
      list_enrollment_classrooms = StudentEnrollmentClassroomsRetriever.call(
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        search_type: :by_date,
        date: '2023-03-10',
        score_type: nil
      )

      list_score_type = list_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].classrooms_grade.exam_rule.score_type
      }.uniq

      expect(list_score_type).to eq([ScoreTypes::NUMERIC_AND_CONCEPT])
    end
  end

  context 'when with_recovery_note_in_step params exist'

  context 'when have students and classroom with different exam rules' do
    it 'should only return enrollment_classrooms with the differentiated exam rule' do
      create_differentiated_exam_rule
      create_student_with_differentiated_exam_rule

      list_enrollment_classrooms = StudentEnrollmentClassroomsRetriever.call(
        classrooms: classroom,
        disciplines: discipline,
        search_type: :by_date_range,
        start_at: '2023-05-17',
        end_at: '2023-10-03',
        opinion_type: '3'
      )

      student_with_differentiated_exam_rule = list_enrollment_classrooms.map { |ec|
        ec[:student_enrollment_classroom].student_enrollment.student.uses_differentiated_exam_rule
      }
      expect(student_with_differentiated_exam_rule).to eq([true])
    end
  end

  context 'when include_inactive is set to false' do
    subject(:list_enrollment_classrooms) {
      StudentEnrollmentClassroomsRetriever.call(
        search_type: :by_date_range,
        classrooms: classroom_grade.classroom_id,
        disciplines: discipline,
        start_at: '2023-02-02',
        end_at: '2023-04-02',
        include_inactive: false
      )
    }

    before do
      create(
        :student_enrollment_classroom,
        student_enrollment_id: student_enrollment_classrooms.first.student_enrollment_id,
        classrooms_grade: classroom_grade,
        joined_at: '2023-05-02',
        left_at: '2023-06-02'
        )
    end

    context 'and show_inactive_enrollments is enabled in configuration' do
      before { GeneralConfiguration.first.update(show_inactive_enrollments: true) }

      it 'returns only active student_enrollment_classrooms in the date_range' do
        expect(list_enrollment_classrooms.size).to eq(3)
      end
    end

    context 'and show_inactive_enrollments is disabled in configuration' do
      before { GeneralConfiguration.first.update(show_inactive_enrollments: false) }

      it 'returns only active student_enrollment_classrooms in the date_range' do
        expect(list_enrollment_classrooms.size).to eq(3)
      end
    end
  end
end

def create_differentiated_exam_rule
  differentiated_exam_rule = create(:exam_rule, opinion_type: '3')
  exam_rule_default = create(:exam_rule, differentiated_exam_rule: differentiated_exam_rule)
  classroom_grade.update(exam_rule: exam_rule_default)
end

def create_student_with_differentiated_exam_rule
  student = create(:student, uses_differentiated_exam_rule: true)
  student_enrollment = create(:student_enrollment, student: student)
  enrollment_classroom = create(
    :student_enrollment_classroom,
    student_enrollment: student_enrollment,
    classrooms_grade: classroom_grade,
    joined_at: '2023-02-02',
    left_at: ''
  )
end

def create_student_enrollment_classrooms_with_status_and_date_base
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

def create_student_enrollment_classrooms_with_status_without_date_base
  student = create(:student)
  enrollment_inactive = create(:student_enrollment, student: student, status: 4)
  @enrollment_classroom_inactive = create(
    :student_enrollment_classroom,
    student_enrollment: enrollment_inactive,
    classrooms_grade: classroom_grade,
    joined_at: '2023-04-04',
    left_at: '2023-03-12'
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

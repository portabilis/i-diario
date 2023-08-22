require 'rails_helper'

RSpec.describe StudentEnrollmentsList, type: :service do
  let(:student_enrollment) { create(:student_enrollment) }
  let(:student_enrollment_classroom) {
    create(
      :student_enrollment_classroom,
      student_enrollment_id: student_enrollment.id
    )
  }
  let(:current_user) { create(:user) }
  let(:classroom_grade) { student_enrollment_classroom.classrooms_grade_id }
  let(:classroom) { student_enrollment_classroom.classrooms_grade.classroom_id }
  let(:discipline) { create(:discipline) }

  describe '#student_enrollments' do
    context 'when parameters are required' do
      subject do
        described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date,
          date: '2019-01-01'
        )
      end

      it 'returns as relation params true' do
        expect(subject.student_enrollments(true).class).to eq(StudentEnrollment::ActiveRecord_Relation)
      end
    end
  end

  describe '#ensure_has_valid_params' do
    context 'when params are incorrect with search_type: :by_date' do
      it 'return with raises ArgumentError to search by date' do
        expect {
          described_class.new(
            classroom: classroom,
            discipline: discipline,
            search_type: :by_date
          )
        }.to raise_error(ArgumentError)
      end
    end

    # context 'when params are incorrect with search_type: :by_year' do
    #   it 'return with raises ArgumentError to search by year' do
    #     expect {
    #       described_class.new(
    #         classroom: classroom,
    #         discipline: discipline,
    #         search_type: :by_year
    #       )
    #     }.to raise_error(ArgumentError)
    #   end
    # end

    context 'when params are incorrect with search_type: :by_date_range' do
      it 'return with raises ArgumentError to search by date range' do
        expect {
          described_class.new(
            classroom: classroom,
            discipline: discipline,
            search_type: :by_date_range
          )
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#student_active?' do
    context 'when searching student by date' do
      let(:student_enrollment_2) { create(:student_enrollment) }
      let(:student_enrollment_classroom_2) {
        create(
          :student_enrollment_classroom,
          student_enrollment_id: student_enrollment_2.id,
          joined_at: '2018-11-01',
          left_at: '2018-12-01'
        )
      }
      let(:classroom_2) { student_enrollment_classroom_2.classrooms_grade.classroom_id }

      it 'return array of enrollment with enrollment_classrooms on the date' do
        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date,
          date: '2018-02-02'
        )
        result = subject.student_enrollments

        expect(result).to eq([student_enrollment])
      end

      it 'return array of enrollment without enrollment_classrooms on the date' do
        subject = described_class.new(
          classroom: classroom_2,
          discipline: discipline,
          search_type: :by_date,
          date: '2018-11-02'
        )
        result = subject.student_enrollments

        expect(result).to eq([student_enrollment_2])
      end
    end

    context 'when searching student by year' do
      it 'return array of enrollment with classroom on the year' do
        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_year,
          year: 2017
        )
        result = subject.student_enrollments

        expect(result).to eq([student_enrollment])
      end

      it 'returns null enrollments for classroom not created for the year' do
        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_year,
          year: 2018
        )
        result = subject.student_enrollments.first

        expect(result).to be_nil
      end
    end

    context 'when searching student by date range' do
      let(:student_enrollment_2) { create(:student_enrollment) }
      let(:student_enrollment_classroom_2) {
        create(
          :student_enrollment_classroom,
          student_enrollment_id: student_enrollment_2.id,
          joined_at: '2017-02-01'
        )
      }
      let(:classroom_2) { student_enrollment_classroom_2.classrooms_grade.classroom_id }

      it 'return array of enrollment with enrollment_classrooms on the date range' do
        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date_range,
          start_at: '2017-01-02',
          end_at: '2017-03-20'
        )
        expect(subject.student_enrollments).to eq([student_enrollment])
      end

      it 'returns empty array of enrollment with enrollment_classrooms on the date range' do
        subject = described_class.new(
          classroom: classroom_2,
          discipline: discipline,
          search_type: :by_date_range,
          start_at: '2015-01-01',
          end_at: '2015-02-01'
        )

        expect(subject.student_enrollments).to be_empty
      end
    end
  end

  describe '#fetch_student_enrollments' do
    context 'when searching student_enrollment with grade' do
      let(:classroom_grades) { create_list(:classrooms_grade, 2, classroom_id: 3) }
      let!(:student_enrollment_classroom_2) {
        create(
          :student_enrollment_classroom,
          classrooms_grade_id: classroom_grades.first.id
        )
      }
      let!(:student_enrollment_classroom_3) {
        create(
          :student_enrollment_classroom,
          classrooms_grade_id: classroom_grades.last.id
        )
      }

      it 'returns array of student_enrollment while include grades' do
        subject = described_class.new(
          classroom: 3,
          discipline: discipline,
          search_type: :by_date,
          date: '2017-11-01',
          grade: classroom_grades.map(&:grade_id)
        )

        expect(subject.student_enrollments).to include(
          student_enrollment_classroom_2.student_enrollment,
          student_enrollment_classroom_3.student_enrollment
        )
      end

      it 'returns empty array of student_enrollment while having no grades' do
        subject = described_class.new(
          classroom: 3,
          discipline: discipline,
          search_type: :by_date,
          date: '2017-11-01',
          grade: classroom_grade
        )

        expect(subject.student_enrollments).to be_empty
      end
    end

    context 'when searching student_enrollment with include_date_range' do

      it 'returns array of student_enrollment include in date_range ' do
        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date,
          date: '2017-01-01',
          include_date_range: true,
          start_at: '2016-02-02',
          end_at: '2017-03-02'
        )

        expect(subject.student_enrollments).to include(student_enrollment)
      end

      it 'returns empty array of student_enrollment while not include in date_range' do
        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date,
          date: '2017-01-01',
          include_date_range: true,
          start_at: '2017-02-02',
          end_at: '2017-03-02'
        )

        expect(subject.student_enrollments).to be_empty
      end
    end

    context 'when searching student_enrollment with opinion_type' do
      let(:exam_rule_2) { create(:exam_rule, opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE) }
      let!(:classroom_grade_2) { create(:classrooms_grade, exam_rule_id: exam_rule_2.id) }
      let!(:student_enrollment_classroom_2) {
        create(
          :student_enrollment_classroom,
          classrooms_grade_id: classroom_grade_2.id
        )
      }

      it 'returns array of student_enrollment while include opition_type' do
        subject = described_class.new(
          classroom: classroom_grade_2.classroom_id,
          discipline: discipline,
          search_type: :by_date,
          date: '2017-01-01',
          opinion_type: exam_rule_2.opinion_type
        )

        expect(subject.student_enrollments).to include(student_enrollment_classroom_2.student_enrollment)
      end

      it 'returns empty array of student_enrollment while not include opinion_type' do
        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date,
          date: '2017-01-01',
          opinion_type: exam_rule_2.opinion_type
        )

        expect(subject.student_enrollments).to be_empty
      end
    end

    context 'when searching student_enrollment with recovery_note_in_step' do
      # let!(:recovery_diary_record) {
      #   create(
      #     :recovery_diary_record,
      #     :with_teacher_discipline_classroom,
      #     :with_students,
      #     classroom_id: classroom,
      #     discipline_id: discipline.id
      #   )
      # }
      # let!(:school_calendar) { create(:school_calendar, unity_id: student_enrollment_classroom.classrooms_grade.classroom.unity_id) }
      # let!(:school_calendar_step) { create(:school_calendar_step, school_calendar_id: school_calendar.id) }
      # # let!(:school_term_recovery_diary_record) {
      # #   create(
      # #     :school_term_recovery_diary_record,
      # #     recovery_diary_record: recovery_diary_record,
      # #     step: school_calendar_step
      # #   )
      # }
      #
      # it 'returns array of student_enrollment while include with_recovery_note_in_step' do
      #   current_user.current_classroom_id = recovery_diary_record.classroom_id
      #   current_user.current_discipline_id = recovery_diary_record.discipline_id
      #   subject = described_class.new(
      #     classroom: classroom,
      #     discipline: discipline,
      #     search_type: :by_date,
      #     date: '2017-01-01',
      #     with_recovery_note_in_step: AffectedScoreTypes::STEP_RECOVERY_SCORE
      #   )
      #   allow(recovery_diary_record).to receive(:current_user).and_return(current_user)
      #   expect(subject.student_enrollments).to include(student_enrollment_classroom.student_enrollment)
      # end
    end

    context 'when searching student_enrollment with show_inactive' do
      let!(:classroom_grades_2) { create(:classrooms_grade) }
      let!(:student_enrollment_2) { create(:student_enrollment, student_id: student_enrollment.student_id) }
      let!(:enrollment_classroom_2) {
        create(
          :student_enrollment_classroom,
          classrooms_grade_id: classroom_grades_2.id,
          student_enrollment_id: student_enrollment_2.id,
          joined_at: '2018-01-01'
        )
      }
      let!(:enrollment_classroom_3) {
        create(
          :student_enrollment_classroom,
          classrooms_grade_id: classroom_grade,
          student_enrollment_id: student_enrollment_2.id,
          joined_at: '2018-03-04'
        )
      }

      it 'returns array of student_enrollment only while inactive' do
        student_enrollment_classroom.update_attribute(:left_at, '2017-12-12')
        student_enrollment.update_attribute(:status, 4)

        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date,
          date: '2017-11-01',
          show_inactive: true
        )

        expect(subject.student_enrollments).to include(student_enrollment)
      end

      it 'returns array of student_enrollment only while active' do
        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date,
          date: '2017-11-01',
          show_inactive: false
        )

        expect(subject.student_enrollments).to include(student_enrollment_classroom.student_enrollment)
      end

      it 'returns array of student_enrollment while active and inactive in the same classroom' do
        student_enrollment_classroom.update_attribute(:left_at, '2017-12-12')
        student_enrollment.update_attribute(:status, 4)

        enrollment_classroom_2.update_attribute(:left_at, '2018-03-03')

        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date_range,
          start_at: '2017-01-01',
          end_at: '2018-04-04',
          show_inactive: true
        )

        expect(subject.student_enrollments).to include(student_enrollment, enrollment_classroom_2.student_enrollment)
      end

      it 'return only one student_enrollment  if has params remove_duplicate_student' do
        enrollment_classroom_2.update_attribute(:left_at, '2017-12-12')
        student_enrollment_2.update_attribute(:status, 4)
        student_enrollment.update_attribute(:changed_at, '2018-01-06 08:46:35')

        enrollment_classroom_3.update_attribute(:left_at, '2018-03-03')
        student_enrollment_2.update_attribute(:changed_at, '2018-01-07 08:46:35')

        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date_range,
          start_at: '2017-01-01',
          end_at: '2018-04-04',
          show_inactive: true,
          remove_duplicate_student: true
        )

        expect(subject.student_enrollments).to include(student_enrollment_2)
        expect(subject.student_enrollments.length).to eql(1)
      end
    end
  end

  describe '#reject_duplicated_students' do
  end

  describe '#remove_not_displayable_students' do
  end
end

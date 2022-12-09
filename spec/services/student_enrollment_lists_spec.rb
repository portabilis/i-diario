require 'rails_helper'

RSpec.describe StudentEnrollmentsList, type: :service do
  let(:student_enrollment) { create(:student_enrollment) }
  let(:student_enrollment_classroom) {
    create(
      :student_enrollment_classroom,
      student_enrollment_id: student_enrollment.id
    )
  }
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

    context 'when params are incorrect with search_type: :by_year' do
      it 'return with raises ArgumentError to search by year' do
        expect {
          described_class.new(
            classroom: classroom,
            discipline: discipline,
            search_type: :by_year
          )
        }.to raise_error(ArgumentError)
      end
    end

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

        expect(subject.student_enrollments).to eq([])
      end
    end
  end

  describe '#fetch_student_enrollments' do
    context 'when searching student_enrollment with grade' do
    end

    context 'when searching student_enrollment with include_date_range' do
    end

    context 'when searching student_enrollment with opinion_type' do
    end

    context 'when searching student_enrollment with with_recovery_note_in_step' do
    end

    context 'when searching student_enrollment with show_inactive' do
    end
  end

  describe '#reject_duplicated_students' do

  end

  describe '#remove_not_displayable_students' do
  end

  describe '#order_by_sequence_and_name' do
  end

end

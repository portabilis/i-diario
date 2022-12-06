require 'rails_helper'

RSpec.describe StudentEnrollmentsList, type: :service do
  let(:student_enrollment_classroom) { create(:student_enrollment_classroom) }
  let(:student_enrollment) { student_enrollment_classroom.student_enrollment_id }
  let(:classroom) { student_enrollment_classroom.classrooms_grade.classroom_id }
  let(:discipline) { create(:discipline) }
  let(:grade) { create(:grade) }
  let(:start_at) { Date.new(classroom.year).beginning_of_year }
  let(:end_at) { Date.new(classroom.year).end_of_year }
  let(:date_not_before) { '2022-05-22' }

  describe '#fetch_student_enrollments' do
    context 'when params are correct with search_type: :by_date' do
      subject do
        described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date,
          date: '2019-01-01'
        )
      end

      it 'returns with only one enrollment' do
        expect(subject.student_enrollments.size).to eq(1)
      end

      it 'returns as relation params true' do
        expect(subject.student_enrollments(true).class).to eq(StudentEnrollment::ActiveRecord_Relation)
      end
    end

    context 'when params are correct with search_type: :by_year' do
      let(:student_enrollment_classroom_2) { create(:student_enrollment_classroom) }
      let(:classroom_2) { student_enrollment_classroom.classrooms_grade.classroom_id }

      it 'returns with only one enrollment' do
        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_year,
          year: 2017
        )

        expect(subject.student_enrollments.size).to eq(1)
      end
    end

    context 'when params are correct with search_type: :by_range_data' do
      let(:student_enrollment_classroom_2) { create(:student_enrollment_classroom) }
      let(:classroom_2) { student_enrollment_classroom.classrooms_grade.classroom_id }

      it 'returns with only one enrollment' do
        subject = described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date_range,
          start_at: '2017-01-01',
          end_at: '2017-03-20'
        )

        expect(subject.student_enrollments.size).to eq(1)
      end
    end

  end
end

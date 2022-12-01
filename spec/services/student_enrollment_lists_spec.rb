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
    subject do
      described_class.new(
        classroom: classroom,
        discipline: discipline,
        search_type: :by_date,
        date: '2019-01-01'
      )
    end

    context 'with only one enrollment' do
      it 'returns that enrollment' do
        expect(subject.student_enrollments.size).to eq(1)
      end
    end

    context 'with only one enrollment' do
      it 'returns that enrollment' do
        expect(subject.student_enrollments.size).to eq(1)
      end
    end


  end
end

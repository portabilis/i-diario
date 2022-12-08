require 'rails_helper'

RSpec.describe StudentEnrollmentsList, type: :service do
  let(:student_enrollment_classroom) { create(:student_enrollment_classroom) }
  let(:student_enrollment) { student_enrollment_classroom.student_enrollment_id }
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
    context 'when params are correct with search_type: :by_date' do
      let(:student_enrollment_2) { create(:student_enrollment) }
      let(:student_enrollment_classroom_2) {
        create(
          :student_enrollment_classroom,
          student_enrollment_id: student_enrollment_2.id,
          joined_at: '2017-11-01'
        )
      }
      let(:classroom_2) { student_enrollment_classroom_2.classrooms_grade.classroom_id }

      subject do
        described_class.new(
          classroom: classroom_2,
          discipline: discipline,
          search_type: :by_date,
          date: '2018-02-02'
        )
      end

      it 'returns with enrollments by date' do
        student_enrollment_classroom = subject.student_enrollments.first.student_enrollment_classrooms

        expect(student_enrollment_classroom).to eq(student_enrollment_2.student_enrollment_classrooms)
      end
    end

    context 'when params are incorrect with search_type: :by_date' do
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

      subject do
        described_class.new(
          classroom: classroom_2,
          discipline: discipline,
          search_type: :by_date,
          date: '2018-12-02'
        )
      end

      it 'returns nil enrollments by date' do
        student_enrollment_classroom = subject.student_enrollments.first&.student_enrollment_classrooms
        expect(student_enrollment_classroom).to be_nil
      end
    end

    context 'when params are correct with search_type: :by_year' do
      subject do
        described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_year,
          year: 2017
        )
      end

      it 'returns enrollment id linked to the class of the year' do
        expect(subject.student_enrollments.first.id).to eq(student_enrollment)
      end
    end

    context 'when params are incorrect with search_type: :by_year' do
      let(:classroom_2) { create(:classroom, year: 2017) }
      let(:classroom_grade) { create(:classrooms_grade, classroom_id: classroom_2.id) }
      let(:student_enrollment_classroom_2) {
        create(
          :student_enrollment_classroom,
          classrooms_grade_id: classroom_grade.id
        )
      }

      subject do
        described_class.new(
          classroom: classroom_2,
          discipline: discipline,
          search_type: :by_year,
          year: 2018
        )
      end

      it 'returns nil enrollments linked to a classroom by year' do
        student_enrollment_classroom = subject.student_enrollments.first&.student_enrollment_classrooms
        expect(student_enrollment_classroom).to be_nil
      end
    end

    context 'when params are correct with search_type: :by_date_range' do
      let(:student_enrollment_2) { create(:student_enrollment) }
      let(:student_enrollment_classroom_2) {
        create(
          :student_enrollment_classroom,
          student_enrollment_id: student_enrollment_2.id,
          joined_at: '2017-02-01',
          left_at: nil
        )
      }
      let(:classroom_2) { student_enrollment_classroom_2.classrooms_grade.classroom_id }

      subject do
        described_class.new(
          classroom: classroom,
          discipline: discipline,
          search_type: :by_date_range,
          start_at: '2017-01-02',
          end_at: '2017-03-20'
        )
      end

      it 'returns with only one enrollment linked to the range_date' do
        expect(subject.student_enrollments.size).to eq(1)
      end
    end

    context 'when params are incorrect with search_type: :by_date_range' do
      let(:student_enrollment_2) { create(:student_enrollment) }
      let(:student_enrollment_classroom_2) {
        create(
          :student_enrollment_classroom,
          student_enrollment_id: student_enrollment_2.id,
          joined_at: '2017-11-01'
        )
      }
      let(:classroom_2) { student_enrollment_classroom_2.classrooms_grade.classroom_id }

      subject do
        described_class.new(
          classroom: classroom_2,
          discipline: discipline,
          search_type: :by_date_range,
          start_at: '2015-01-01',
          end_at: '2015-02-01'
        )
      end

      it 'returns blank enrollment linked to the range_date ' do
        expect(subject.student_enrollments).to eq([])
      end
    end

  end

  describe '#fetch_student_enrollments' do

  end

end

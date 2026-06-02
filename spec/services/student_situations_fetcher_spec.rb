# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentSituationsFetcher, type: :service do
  describe '.call' do
    let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
    let(:discipline) { create(:discipline) }
    let(:date) { Date.current }
    let(:enrollment) { create(:student_enrollment) }
    let(:enrollment_ids) { [enrollment.id] }

    let(:default_params) do
      {
        enrollment_ids: enrollment_ids,
        classroom: classroom,
        discipline: discipline,
        date: date
      }
    end

    context 'when enrollment_ids is empty' do
      it 'returns the empty result without hitting the database' do
        expect(StudentsInDependency).not_to receive(:call)
        expect(ActiveSearch).not_to receive(:new)

        result = described_class.call(default_params.merge(enrollment_ids: []))

        expect(result).to eq(
          dependencies: {},
          exemptions: {},
          active_on_date_ids: Set.new,
          enrollments_in_active_search: []
        )
      end
    end

    context 'when enrollment_ids is present' do
      it 'returns a hash with the 4 expected keys' do
        result = described_class.call(default_params)

        expect(result.keys).to contain_exactly(
          :dependencies,
          :exemptions,
          :active_on_date_ids,
          :enrollments_in_active_search
        )
      end

      it 'returns dependencies indexed by student_enrollment_id when the student is in dependence' do
        create(:student_enrollment_dependence, student_enrollment: enrollment, discipline: discipline)

        result = described_class.call(default_params)

        expect(result[:dependencies][enrollment.id]).to contain_exactly(discipline.id)
      end

      it 'returns empty dependencies when the student is not in dependence' do
        result = described_class.call(default_params)

        expect(result[:dependencies]).to be_empty
      end
    end

    context '#exemptions' do
      it 'returns empty exemptions when step_number is nil' do
        create(
          :student_enrollment_exempted_discipline,
          student_enrollment: enrollment,
          discipline: discipline,
          steps: '1'
        )

        result = described_class.call(default_params)

        expect(result[:exemptions]).to be_empty
      end

      it 'returns empty exemptions when discipline is nil' do
        result = described_class.call(default_params.merge(discipline: nil, step_number: 1))

        expect(result[:exemptions]).to be_empty
      end

      it 'returns exemptions when step_number and discipline are provided' do
        create(
          :student_enrollment_exempted_discipline,
          student_enrollment: enrollment,
          discipline: discipline,
          steps: '1'
        )

        result = described_class.call(default_params.merge(step_number: 1))

        expect(result[:exemptions][enrollment.id]).to eq(1)
      end
    end

    context 'parameter validation' do
      it 'raises KeyError when enrollment_ids is missing' do
        expect {
          described_class.call(classroom: classroom, discipline: discipline, date: date)
        }.to raise_error(KeyError, /enrollment_ids/)
      end

      it 'raises KeyError when classroom is missing' do
        expect {
          described_class.call(enrollment_ids: enrollment_ids, discipline: discipline, date: date)
        }.to raise_error(KeyError, /classroom/)
      end

      it 'raises KeyError when discipline is missing' do
        expect {
          described_class.call(enrollment_ids: enrollment_ids, classroom: classroom, date: date)
        }.to raise_error(KeyError, /discipline/)
      end

      it 'raises KeyError when date is missing' do
        expect {
          described_class.call(enrollment_ids: enrollment_ids, classroom: classroom, discipline: discipline)
        }.to raise_error(KeyError, /date/)
      end
    end

    context '#active_on_date_ids' do
      let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }

      def enroll(status:, joined_at: '2017-01-01', left_at: '')
        student_enrollment = create(:student_enrollment, status: status)
        create(
          :student_enrollment_classroom,
          classrooms_grade: classrooms_grade,
          student_enrollment: student_enrollment,
          joined_at: joined_at,
          left_at: left_at
        )
        student_enrollment
      end

      it 'includes enrollments enrolled on the date with an attending status' do
        studying = enroll(status: StudentEnrollmentStatus::STUDYING)

        result = described_class.call(default_params.merge(enrollment_ids: [studying.id]))

        expect(result[:active_on_date_ids]).to contain_exactly(studying.id)
      end

      it 'excludes transferred/abandonment enrollments even within the date window' do
        studying = enroll(status: StudentEnrollmentStatus::STUDYING)
        transferred = enroll(status: StudentEnrollmentStatus::TRANSFERRED)
        abandoned = enroll(status: StudentEnrollmentStatus::ABANDONMENT)

        result = described_class.call(
          default_params.merge(enrollment_ids: [studying.id, transferred.id, abandoned.id])
        )

        expect(result[:active_on_date_ids]).to contain_exactly(studying.id)
      end

      it 'excludes enrollments outside the date window' do
        left = enroll(status: StudentEnrollmentStatus::STUDYING, joined_at: '2017-01-01', left_at: '2017-02-01')

        result = described_class.call(default_params.merge(enrollment_ids: [left.id]))

        expect(result[:active_on_date_ids]).to be_empty
      end
    end

    context '#enrollments_in_active_search' do
      it 'returns an Array (empty by default)' do
        result = described_class.call(default_params)

        expect(result[:enrollments_in_active_search]).to eq([])
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Api::ListScheduledEvaluationsByClassroomService do
  def build_avaliation_recovery_diary_record
    teacher = create(:teacher)
    avaliation = create(:avaliation, :with_teacher_discipline_classroom, teacher: teacher)
    recovery_diary_record = create(
      :recovery_diary_record,
      :with_students,
      classroom: avaliation.classroom,
      discipline: avaliation.discipline,
      teacher: teacher,
      teacher_id: teacher.id
    )
    recovery_diary_record.not_validate_columns = true

    create(:avaliation_recovery_diary_record, avaliation: avaliation, recovery_diary_record: recovery_diary_record)
  end

  describe '.call' do
    context 'with a numeric avaliation' do
      let(:avaliation) { create(:avaliation, :with_teacher_discipline_classroom) }
      let(:classroom) { avaliation.classroom }

      it 'includes it as numerical_exam with the test_setting maximum_score' do
        result = described_class.call(classroom_api_code: classroom.api_code, year: classroom.year)

        item = result[:data].find { |i| i[:id] == avaliation.id }
        expect(item).not_to be_nil
        expect(item[:type]).to eq('numerical_exam')
        expect(item[:score_type]).to eq('numeric')
        expect(item[:maximum_score]).to eq(avaliation.test_setting.maximum_score)
        expect(item[:discipline][:id]).to eq(avaliation.discipline.api_code)
        expect(item[:date]).to eq(avaliation.test_date)
      end

      it 'filters by discipline_id' do
        other_discipline = create(:discipline)

        result = described_class.call(
          classroom_api_code: classroom.api_code, year: classroom.year, discipline_api_code: other_discipline.api_code
        )

        expect(result[:data]).to be_empty
      end

      it 'filters out avaliations before after_date' do
        result = described_class.call(
          classroom_api_code: classroom.api_code, year: classroom.year, after_date: avaliation.test_date + 1.day
        )

        expect(result[:data]).to be_empty
      end

      it 'includes avaliations on or after after_date' do
        result = described_class.call(
          classroom_api_code: classroom.api_code, year: classroom.year, after_date: avaliation.test_date
        )

        expect(result[:data].map { |i| i[:id] }).to include(avaliation.id)
      end
    end

    context 'with a parallel recovery (AvaliationRecoveryDiaryRecord)' do
      let(:avaliation_recovery) { build_avaliation_recovery_diary_record }
      let(:classroom) { avaliation_recovery.recovery_diary_record.classroom }

      it 'includes it as parallel_recovery' do
        result = described_class.call(classroom_api_code: classroom.api_code, year: classroom.year)

        item = result[:data].find { |i| i[:id] == avaliation_recovery.recovery_diary_record.id }
        expect(item).not_to be_nil
        expect(item[:type]).to eq('parallel_recovery')
      end

      it 'filters it out when after_date is later than the underlying avaliation test_date' do
        result = described_class.call(
          classroom_api_code: classroom.api_code,
          year: classroom.year,
          after_date: avaliation_recovery.avaliation.test_date + 1.day
        )

        expect(result[:data]).to be_empty
      end
    end

    context 'with a school term recovery (SchoolTermRecoveryDiaryRecord)' do
      let(:school_term_recovery) { create(:school_term_recovery_diary_record) }
      let(:classroom) { school_term_recovery.recovery_diary_record.classroom }

      it 'includes it as school_term_recovery' do
        result = described_class.call(classroom_api_code: classroom.api_code, year: classroom.year)

        item = result[:data].find { |i| i[:id] == school_term_recovery.recovery_diary_record.id }
        expect(item).not_to be_nil
        expect(item[:type]).to eq('school_term_recovery')
      end

      it 'filters by step_number' do
        result = described_class.call(
          classroom_api_code: classroom.api_code, year: classroom.year, step_number: school_term_recovery.step_number
        )
        expect(result[:data]).not_to be_empty

        other_result = described_class.call(
          classroom_api_code: classroom.api_code,
          year: classroom.year,
          step_number: school_term_recovery.step_number + 1
        )
        expect(other_result[:data]).to be_empty
      end

      it 'filters it out when after_date is later than its recorded_at' do
        result = described_class.call(
          classroom_api_code: classroom.api_code,
          year: classroom.year,
          after_date: school_term_recovery.recorded_at + 1.day
        )

        expect(result[:data]).to be_empty
      end
    end

    context 'with a final recovery (FinalRecoveryDiaryRecord)' do
      let(:final_recovery) { create(:final_recovery_diary_record) }
      let(:classroom) { final_recovery.recovery_diary_record.classroom }

      it 'includes it as final_recovery' do
        result = described_class.call(classroom_api_code: classroom.api_code, year: classroom.year)

        item = result[:data].find { |i| i[:id] == final_recovery.recovery_diary_record.id }
        expect(item).not_to be_nil
        expect(item[:type]).to eq('final_recovery')
        expect(item[:maximum_score]).to eq(classroom.first_exam_rule.final_recovery_maximum_score)
      end

      it 'filters it out when after_date is later than its recorded_at' do
        result = described_class.call(
          classroom_api_code: classroom.api_code,
          year: classroom.year,
          after_date: final_recovery.recovery_diary_record.recorded_at + 1.day
        )

        expect(result[:data]).to be_empty
      end
    end

    context 'when the classroom does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect do
          described_class.call(classroom_api_code: 'INEXISTENT', year: 2026)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

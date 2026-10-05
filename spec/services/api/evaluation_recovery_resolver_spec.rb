require 'rails_helper'

RSpec.describe Api::EvaluationRecoveryResolver do
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

  describe '.type_for' do
    it 'returns parallel_recovery for a parallel recovery diary record' do
      record = build_avaliation_recovery_diary_record.recovery_diary_record.reload

      expect(described_class.type_for(record)).to eq('parallel_recovery')
    end

    it 'returns school_term_recovery for a school term recovery diary record' do
      record = create(:school_term_recovery_diary_record).recovery_diary_record.reload

      expect(described_class.type_for(record)).to eq('school_term_recovery')
    end

    it 'returns final_recovery for a final recovery diary record' do
      record = create(:final_recovery_diary_record).recovery_diary_record.reload

      expect(described_class.type_for(record)).to eq('final_recovery')
    end
  end

  describe '.step_for' do
    it 'resolves the step from the linked avaliation for a parallel recovery' do
      avaliation_recovery = build_avaliation_recovery_diary_record
      record = avaliation_recovery.recovery_diary_record.reload

      expect(described_class.step_for(record)).to eq(avaliation_recovery.avaliation.current_step)
    end

    it 'resolves its own step for a school term recovery' do
      school_term_recovery = create(:school_term_recovery_diary_record)
      record = school_term_recovery.recovery_diary_record.reload

      expect(described_class.step_for(record)).to eq(school_term_recovery.step)
    end

    it 'resolves the last step of the year for a final recovery' do
      final_recovery = create(:final_recovery_diary_record)
      record = final_recovery.recovery_diary_record.reload

      expect(described_class.step_for(record)).to eq(StepsFetcher.new(record.classroom).last_step_by_year)
    end
  end

  describe '.maximum_score_for' do
    it 'delegates to RecoveryDiaryRecordStudent#maximum_score without needing a persisted student' do
      final_recovery = create(:final_recovery_diary_record)
      record = final_recovery.recovery_diary_record.reload

      expect(described_class.maximum_score_for(record))
        .to eq(record.classroom.first_exam_rule.final_recovery_maximum_score)
    end
  end

  describe '.title_for' do
    it 'combines the type label with the discipline name' do
      school_term_recovery = create(:school_term_recovery_diary_record)
      record = school_term_recovery.recovery_diary_record.reload

      expect(described_class.title_for(record)).to eq("Recuperação de Etapa - #{record.discipline}")
    end
  end
end

require 'rails_helper'

RSpec.describe StudentPartialScoresFetcher, type: :service do
  let(:avaliation) { create(:avaliation) }
  let(:classroom) { avaliation.classroom }
  let(:student) { create(:student) }
  let(:school_calendar_step) { create(:school_calendar_step, school_calendar: avaliation.school_calendar) }

  def create_daily_note_student(avaliation, student, note:)
    daily_note = create(:daily_note, avaliation: avaliation)
    create(:daily_note_student, daily_note: daily_note, student: student, note: note)
  end

  describe '#fetch!' do
    it 'returns the discipline in uppercase, the localized score and weight for a launched note' do
      create_daily_note_student(avaliation, student, note: 8.5)

      result = described_class.new(student.id, school_calendar_step.id, classroom.id).fetch!

      expect(result.size).to eq(1)
      expect(result.first[:discipline]).to eq(avaliation.discipline.to_s.upcase)
      expect(result.first[:score]).to eq('8,5')
      expect(result.first[:weight]).to eq('10,0')
    end

    it 'returns a blank score when the student has no launched note for the avaliation' do
      result = described_class.new(student.id, school_calendar_step.id, classroom.id).fetch!

      expect(result.first[:score]).to be_blank
    end

    context 'with an active recovery' do
      it "uses the recovery score when it's higher than the regular note" do
        create_daily_note_student(avaliation, student, note: 4)

        recovery_diary_record = create(
          :recovery_diary_record, classroom: classroom, discipline: avaliation.discipline
        )
        create(:avaliation_recovery_diary_record, avaliation: avaliation, recovery_diary_record: recovery_diary_record)
        create(:recovery_diary_record_student, recovery_diary_record: recovery_diary_record, student: student, score: 9)

        result = described_class.new(student.id, school_calendar_step.id, classroom.id).fetch!

        expect(result.first[:score]).to eq('9,0')
      end
    end

    context 'with a sum calculation type test_setting_test' do
      it 'uses the test_setting_test weight as maximum_score' do
        test_setting = create(:test_setting_with_sum_calculation_type)
        avaliation_with_test = create(
          :avaliation, test_setting: test_setting, test_setting_test: test_setting.tests.first
        )
        create_daily_note_student(avaliation_with_test, student, note: 5)
        step = create(:school_calendar_step, school_calendar: avaliation_with_test.school_calendar)

        result = described_class.new(student.id, step.id, avaliation_with_test.classroom.id).fetch!

        expect(result.first[:weight]).to eq('10,0')
      end
    end

    # A busca em lote de DailyNoteStudent (uma query para todas as avaliations da turma) é o que
    # evita que o custo cresça linearmente com o número de avaliations de uma etapa.
    it 'does not run more queries per avaliation (no N+1)' do
      create_daily_note_student(avaliation, student, note: 8)
      fetch = -> { described_class.new(student.id, school_calendar_step.id, classroom.id).fetch! }

      queries_with_one_avaliation = count_queries(&fetch)

      other_avaliation = create(:avaliation, classroom: classroom, school_calendar: avaliation.school_calendar)
      create_daily_note_student(other_avaliation, student, note: 6)

      expect(count_queries(&fetch)).to eq(queries_with_one_avaliation)
    end
  end
end

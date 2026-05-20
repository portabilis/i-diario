require 'rails_helper'

RSpec.describe PartialScoreRecordReport, type: :report do
  let!(:entity_configuration) { create(:entity_configuration) }
  let!(:discipline) { create(:discipline) }
  let!(:classroom) do
    create(
      :classroom,
      :with_classroom_semester_steps,
      :with_teacher_discipline_classroom,
      :with_student_enrollment_classroom,
      discipline: discipline
    )
  end
  let!(:student_enrollment_classroom) { classroom.student_enrollment_classrooms.first }
  let!(:student_enrollment) { student_enrollment_classroom.student_enrollment }
  let!(:student) { student_enrollment.student }
  let!(:test_setting) { create(:test_setting) }
  let(:school_calendar_step) { classroom.calendar.classroom_steps.first }
  let(:unity) { classroom.unity }

  describe '.build' do
    it 'renders the report without raising' do
      subject = described_class.build(
        entity_configuration,
        classroom.year,
        school_calendar_step,
        [student],
        unity,
        classroom,
        test_setting
      )

      expect(subject).to be_truthy
    end
  end

  describe '#score_without_note?' do
    subject(:report) { described_class.new }

    it 'returns true when the score is blank (empty string or nil)' do
      expect(report.send(:score_without_note?, '')).to eq(true)
      expect(report.send(:score_without_note?, nil)).to eq(true)
    end

    it 'returns true when the score is "N" (não enturmado)' do
      expect(report.send(:score_without_note?, 'N')).to eq(true)
    end

    it 'returns true when the score is "-" (sem nota lançada)' do
      expect(report.send(:score_without_note?, '-')).to eq(true)
    end

    it 'returns false for a numeric-formatted note (real score is preserved)' do
      expect(report.send(:score_without_note?, '8,0')).to eq(false)
    end

    it 'returns false for "D" — the dispensa marker is preserved, not replaced by DP' do
      expect(report.send(:score_without_note?, 'D')).to eq(false)
    end

    it 'returns false for "BA" — the busca ativa marker is preserved, not replaced by DP' do
      expect(report.send(:score_without_note?, 'BA')).to eq(false)
    end
  end

  describe '#student_in_dependence? + #dependence_discipline_ids' do
    let(:report) do
      r = described_class.new
      r.instance_variable_set(:@classroom, classroom)
      r.instance_variable_set(:@school_calendar_step, school_calendar_step)
      r
    end

    context 'when the student has no dependence registered' do
      it 'returns an empty list of dependence disciplines' do
        expect(report.send(:dependence_discipline_ids, student.id)).to eq([])
      end

      it 'returns false for any discipline' do
        expect(report.send(:student_in_dependence?, student.id, discipline.id)).to eq(false)
      end
    end

    context 'when the student has a dependence in the report classroom' do
      before do
        create(:student_enrollment_dependence, student_enrollment: student_enrollment, discipline: discipline)
      end

      it 'returns the dependence discipline id' do
        expect(report.send(:dependence_discipline_ids, student.id)).to contain_exactly(discipline.id)
      end

      it 'returns true for the dependence discipline' do
        expect(report.send(:student_in_dependence?, student.id, discipline.id)).to eq(true)
      end

      it 'returns false for an unrelated discipline' do
        other_discipline = create(:discipline)

        expect(report.send(:student_in_dependence?, student.id, other_discipline.id)).to eq(false)
      end
    end

    # Caso aluna ANA DA SILVA: aluno com mais de uma matrícula no ano —
    # uma regular + uma onde a dependência está registrada. O `student_enrollment` precisa
    # filtrar pela turma do relatório, senão pega a matrícula errada e não detecta a dependência.
    context 'when the student has another enrollment in a different classroom with dependence' do
      let!(:other_classroom) { create(:classroom, :with_classroom_semester_steps) }
      let!(:other_enrollment) { create(:student_enrollment, student: student) }

      before do
        classrooms_grade = create(:classrooms_grade, classroom: other_classroom)
        create(
          :student_enrollment_classroom,
          classrooms_grade: classrooms_grade,
          student_enrollment: other_enrollment
        )
        # Dependência registrada APENAS na matrícula da outra turma — não deve aparecer
        # quando o relatório é gerado para a turma corrente.
        create(:student_enrollment_dependence, student_enrollment: other_enrollment, discipline: discipline)
      end

      it 'does not pick the dependence from the unrelated classroom' do
        expect(report.send(:student_in_dependence?, student.id, discipline.id)).to eq(false)
      end
    end
  end
end

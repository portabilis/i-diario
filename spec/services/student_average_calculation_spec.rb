require 'spec_helper_lite'
require 'enumerate_it'

require 'app/services/student_average_calculator'
require 'app/queries/student_notes_query'

RSpec.describe StudentAverageCalculator, type: :service do
  let(:student) { double(:student) }
  let(:classroom) { double(:classroom) }
  let(:discipline) { double(:discipline) }
  let(:school_calendar_step) { double(:school_calendar_step) }
  let(:start_at) { double(:start_at) }
  let(:end_at) { double(:end_at) }
  let(:student_notes_query) { double(:student_notes_query) }
  let(:complementary_exam_calculator) { double(:complementary_exam_calculator) }
  let(:test_setting) { double(:test_setting) }
  let(:sum_calculation_type?) { false }
  let(:arithmetic_calculation_type?) { false }
  let(:arithmetic_and_sum_calculation_type?) { false }
  let(:exam_rule) { double(:exam_rule) }
  let(:score_rounder) { double(:score_rounder) }
  let(:student_avaliation_exemption_query) { double(:student_avaliation_exemption_query) }
  let(:maximum_score) { double(:maximum_score) }
  let(:score_1) { double(:score_1) }
  let(:score_2) { double(:score_2) }
  let(:students_1) { double(:students_1) }
  let(:students_2) { double(:students_2) }
  let(:student_1) { double(:student_1) }
  let(:student_2) { double(:student_2) }
  let(:discipline_id) { double(:discipline_id) }
  let(:classroom_id) { double(:classroom_id) }

  let(:daily_note_student_1) { double(:daily_note_student_1) }
  let(:daily_note_student_2) { double(:daily_note_student_2) }
  let(:daily_note_student_3) { double(:daily_note_student_3) }
  let(:recovery_diary_record_1) { double(:recovery_diary_record_1) }
  let(:recovery_diary_record_2) { double(:recovery_diary_record_2) }
  let(:avaliation_recovery_diary_record_1) { double(:avaliation_recovery_diary_record_1) }
  let(:avaliation_recovery_diary_record_2) { double(:avaliation_recovery_diary_record_2) }
  let(:daily_note_1) { double(:daily_note_student_1) }
  let(:daily_note_2) { double(:daily_note_student_2) }
  let(:daily_note_3) { double(:daily_note_student_3) }
  let(:avaliation_1) { double(:avaliation_1) }
  let(:avaliation_2) { double(:avaliation_2) }
  let(:avaliation_3) { double(:avaliation_3) }

  let(:weight_avaliation_1) { double(:weight_avaliation_1) }
  let(:weight_avaliation_2) { double(:weight_avaliation_2) }
  let(:weight_avaliation_3) { double(:weight_avaliation_3) }

  let(:avaliation_1_exempted?) { false }
  let(:avaliation_2_exempted?) { false }
  let(:avaliation_3_exempted?) { false }

  let(:recovered_note_1) { nil }
  let(:recovered_note_2) { nil }
  let(:recovered_note_3) { nil }
  let(:daily_note_students) { [] }
  let(:recovery_diary_records) { [] }
  let(:transfer_notes) { [] }
  let(:previous_enrollments_daily_note_students) { [] }

  subject do
    StudentAverageCalculator.new(student)
  end

  before do
    stub_school_calendar_step
    stub_notes_query
    stub_test_setting
    stub_score_rounder
    stub_classroom
    stub_student_avaliation_exemption_query
    stub_daily_note_student_1
    stub_daily_note_student_2
    stub_daily_note_student_3
    stub_recovery_diary_record_1
    stub_recovery_diary_record_2
    stub_avaliations
    stub_student
    stub_discipline
    stub_classroom
    stub_recovery_diary_records
    stub_avaliation_recovery_diary_records
    stub_complementary_exam_calculator
  end

  describe '#calculate' do
    context 'when the calculation type is sum' do
      let(:recovered_note_1) { 9.0 }
      let(:recovered_note_2) { 2.0 }
      let(:sum_calculation_type?) { true }
      let(:daily_note_students) { [daily_note_student_1, daily_note_student_2] }

      before { allow(score_rounder).to receive(:round).with(11.0).and_return(11.0) }

      it "should calculate the average correctly" do
        expect(subject.calculate(classroom, discipline, school_calendar_step)).to eq(11.0)
      end
    end

    context 'when the calculation type is arithmetic' do
      let(:recovered_note_1) { 9.0 }
      let(:recovered_note_2) { 8.0 }
      let(:recovered_note_3) { 10.0 }
      let(:arithmetic_calculation_type?) { true }
      let(:daily_note_students) { [daily_note_student_1, daily_note_student_2, daily_note_student_3] }

      before { allow(score_rounder).to receive(:round).with(9.0).and_return(9.0) }

      it "should calculate the average correctly" do
        expect(subject.calculate(classroom, discipline, school_calendar_step)).to eq(9.0)
      end

      context 'with one exempted avaliation' do
        let(:avaliation_3_exempted?) { true }
        let(:recovered_note_3) { nil }

        before { allow(score_rounder).to receive(:round).with(8.5).and_return(8.5) }

        it "should not consider the exempted avaliation" do
          expect(subject.calculate(classroom, discipline, school_calendar_step)).to eq(8.5)
        end
      end
    end

    context "when the calculation type is arithmetic and sum" do
      let(:recovered_note_1) { 9.0 }
      let(:recovered_note_2) { 8.0 }
      let(:recovered_note_3) { 10.0 }
      let(:arithmetic_and_sum_calculation_type?) { true }
      let(:daily_note_students) { [daily_note_student_1, daily_note_student_2, daily_note_student_3] }
      let(:weight_avaliation_1) { 10 }
      let(:weight_avaliation_2) { 10 }
      let(:weight_avaliation_3) { 10 }
      let(:maximum_score) { 10 }

      before { allow(score_rounder).to receive(:round).with(9.0).and_return(9.0) }

      it "should calculate correctly" do
        expect(subject.calculate(classroom, discipline, school_calendar_step)).to eq(9.0)
      end

      context "having avaliations with different weights" do
        let(:recovered_note_1) { 9.0 }
        let(:recovered_note_2) { 8.0 }
        let(:recovered_note_3) { 10.0 }
        let(:weight_avaliation_1) { 9.0 }
        let(:weight_avaliation_2) { 8.0 }
        let(:weight_avaliation_3) { 10.0 }

        before { allow(score_rounder).to receive(:round).with(10.0).and_return(10.0) }

        it "should return the max note" do
          expect(subject.calculate(classroom, discipline, school_calendar_step)).to eq(10.0)
        end
      end

      context "with one exempted avaliation" do
        let(:avaliation_3_exempted?) { true }
        let(:recovered_note_1) { 9.0 }
        let(:recovered_note_2) { 8.0 }
        let(:recovered_note_3) { nil }
        let(:weight_avaliation_1) { 10 }
        let(:weight_avaliation_2) { 10 }
        let(:weight_avaliation_3) { 10 }

        before { allow(score_rounder).to receive(:round).with(8.5).and_return(8.5) }

        it "should not consider the exempted avaliation weight" do
          expect(subject.calculate(classroom, discipline, school_calendar_step)).to eq(8.5)
        end
      end
    end

    context 'when the calculation type is sum and have no daily_note_student' do
      let(:score_1) { 9.0 }
      let(:score_2) { 2.0 }
      let(:sum_calculation_type?) { true }
      let(:recovery_diary_records) { [recovery_diary_record_1, recovery_diary_record_2] }

      before { allow(score_rounder).to receive(:round).with(11.0).and_return(11.0) }

      it "calculates average using recovery_diary_records without daily_note_student" do
        expect(subject.calculate(classroom, discipline, school_calendar_step)).to eq(11.0)
      end
    end

    context "when the calculation type is arithmetic and sum" do
      context "and have no daily_note_student" do
        let(:score_1) { 4.0 }
        let(:score_2) { 3.0 }
        let(:weight_avaliation_1) { 5.0 }
        let(:weight_avaliation_2) { 5.0 }
        let(:maximum_score) { 10 }
        let(:arithmetic_and_sum_calculation_type?) { true }
        let(:recovery_diary_records) { [recovery_diary_record_1, recovery_diary_record_2] }

        before { allow(score_rounder).to receive(:round).with(7.0).and_return(7.0) }

        it "calculates average using recovery_diary_records without daily_note_student" do
          expect(subject.calculate(classroom, discipline, school_calendar_step)).to eq(7.0)
        end
      end
    end

    it 'expects to call score_rounder with correct params' do
      score_rounder = double(:score_rounder)

      expect(ScoreRounder).to receive(:new)
        .with(classroom, RoundedAvaliations::NUMERICAL_EXAM)
        .and_return(score_rounder)
        .at_least(:once)

      expect(score_rounder).to receive(:round)
        .with(anything)
        .at_least(:once)

      subject.calculate(classroom, discipline, school_calendar_step)
    end
  end

  def stub_school_calendar_step
    allow(school_calendar_step).to receive(:start_at).and_return(start_at)
    allow(school_calendar_step).to receive(:end_at).and_return(end_at)
    allow(school_calendar_step).to receive(:test_setting).and_return(test_setting)
    allow(start_at).to receive(:to_date).and_return(start_at)
    allow(end_at).to receive(:to_date).and_return(end_at)
  end

  def stub_notes_query
    stub_const('StudentNotesQuery', Class.new)
    allow(StudentNotesQuery).to(
      receive(:new).with(student, discipline, classroom, start_at, end_at).and_return(student_notes_query)
    )
    allow(student_notes_query).to receive(:daily_note_students).and_return(daily_note_students)
    allow(student_notes_query).to receive(:recovery_diary_records).and_return(recovery_diary_records)
    allow(student_notes_query).to receive(:transfer_notes).and_return(transfer_notes)
    allow(student_notes_query).to(
      receive(:previous_enrollments_daily_note_students).and_return(previous_enrollments_daily_note_students)
    )
  end

  def stub_complementary_exam_calculator
    stub_const('ComplementaryExamCalculator', Class.new)

    allow(ComplementaryExamCalculator).to(
      receive(:new)
        .with(
          [AffectedScoreTypes::STEP_AVERAGE, AffectedScoreTypes::BOTH],
          student.id,
          discipline.id,
          classroom.id,
          school_calendar_step
        ).and_return(complementary_exam_calculator)
    )

    allow(complementary_exam_calculator).to(
      receive(:calculate).with(anything) { |value| value }
    )

    allow(complementary_exam_calculator).to(
      receive(:calculate_integral).with(anything) { |value| value }
    )
  end

  def stub_test_setting
    allow(test_setting).to receive(:sum_calculation_type?).and_return(sum_calculation_type?)
    allow(test_setting).to receive(:arithmetic_calculation_type?).and_return(arithmetic_calculation_type?)
    allow(test_setting).to receive(:arithmetic_and_sum_calculation_type?).and_return(arithmetic_and_sum_calculation_type?)
    allow(test_setting).to receive(:maximum_score).and_return(maximum_score)
  end

  def stub_daily_note_student_1
    allow(daily_note_student_1).to receive(:recovered_note).and_return(recovered_note_1)
    allow(daily_note_student_1).to receive(:daily_note).and_return(daily_note_1)
    allow(daily_note_1).to receive(:avaliation).and_return(avaliation_1)
  end

  def stub_daily_note_student_2
    allow(daily_note_student_2).to receive(:recovered_note).and_return(recovered_note_2)
    allow(daily_note_student_2).to receive(:daily_note).and_return(daily_note_2)
    allow(daily_note_2).to receive(:avaliation).and_return(avaliation_2)
  end

  def stub_daily_note_student_3
    allow(daily_note_student_3).to receive(:recovered_note).and_return(recovered_note_3)
    allow(daily_note_student_3).to receive(:daily_note).and_return(daily_note_3)
    allow(daily_note_3).to receive(:avaliation).and_return(avaliation_3)
  end

  def stub_recovery_diary_record_1
    allow(recovery_diary_record_1).to receive(:students).and_return(students_1)
    allow(students_1).to receive(:find_by_student_id).and_return(student_1)
    allow(student_1).to receive(:score).and_return(score_1)
  end

  def stub_recovery_diary_record_2
    allow(recovery_diary_record_2).to receive(:students).and_return(students_2)
    allow(students_2).to receive(:find_by_student_id).and_return(student_2)
    allow(student_2).to receive(:score).and_return(score_2)
  end

  def stub_score_rounder
    stub_const('ScoreRounder', Class.new)
    allow(ScoreRounder).to(
      receive(:new).with(classroom, RoundedAvaliations::NUMERICAL_EXAM).and_return(score_rounder)
    )
  end

  def stub_student_avaliation_exemption_query
    stub_const('StudentAvaliationExemptionQuery', Class.new)
    allow(StudentAvaliationExemptionQuery).to(
      receive(:new).and_return(student_avaliation_exemption_query)
    )
    allow(student_avaliation_exemption_query).to(
      receive(:is_exempted).with(avaliation_1).and_return(avaliation_1_exempted?)
    )
    allow(student_avaliation_exemption_query).to(
      receive(:is_exempted).with(avaliation_2).and_return(avaliation_2_exempted?)
    )
    allow(student_avaliation_exemption_query).to(
      receive(:is_exempted).with(avaliation_3).and_return(avaliation_3_exempted?)
    )
  end

  def stub_classroom
    allow(classroom).to receive(:exam_rule).and_return(exam_rule)
  end

  def stub_avaliations
    allow(avaliation_1).to receive(:weight).and_return(weight_avaliation_1)
    allow(avaliation_2).to receive(:weight).and_return(weight_avaliation_2)
    allow(avaliation_3).to receive(:weight).and_return(weight_avaliation_3)
  end

  def stub_student
    allow(student).to receive(:id).and_return(student_1)
  end

  def stub_discipline
    allow(discipline).to receive(:id).and_return(discipline_id)
  end

  def stub_classroom
    allow(classroom).to receive(:id).and_return(classroom_id)
  end

  def stub_recovery_diary_records
    allow(recovery_diary_record_1).to receive(:avaliation_recovery_diary_record).and_return(avaliation_recovery_diary_record_1)
    allow(recovery_diary_record_2).to receive(:avaliation_recovery_diary_record).and_return(avaliation_recovery_diary_record_2)
  end

  def stub_avaliation_recovery_diary_records
    allow(avaliation_recovery_diary_record_1).to receive(:avaliation).and_return(avaliation_1)
    allow(avaliation_recovery_diary_record_2).to receive(:avaliation).and_return(avaliation_2)
  end
end

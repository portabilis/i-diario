require 'rails_helper'

RSpec.describe StudentAverageCalculator, type: :service do
  let(:student) { create(:student) }
  let(:student_enrollment) { create(:student_enrollment, student: student) }
  let(:teacher) { create(:teacher) }
  let(:classroom) {
    create(
      :classroom,
      :with_student_enrollment_classroom,
      teacher: teacher,
      student_enrollment: student_enrollment
    )
  }
  let(:discipline) { create(:discipline, teacher: teacher) }
  let(:school_calendar_step) { create(:school_calendar_step) }
  let(:start_at) { Date.new(classroom.year).beginning_of_year }
  let(:end_at) { Date.new(classroom.year).end_of_year }

  let(:student_notes_query) { double(:student_notes_query) }

  let(:complementary_exam_calculator) { double(:complementary_exam_calculator) }
  let(:test_setting) { double(:test_setting) }
  let(:sum_calculation_type?) { false }
  let(:arithmetic_calculation_type?) { false }
  let(:arithmetic_and_sum_calculation_type?) { false }

  let(:score_rounder) { double(:score_rounder) }
  let(:student_avaliation_exemption_query) { double(:student_avaliation_exemption_query) }
  let(:maximum_score) { double(:maximum_score) }
  let(:score_1) { double(:score_1) }
  let(:score_2) { double(:score_2) }
  let(:students_1) { double(:students_1) }
  let(:students_2) { double(:students_2) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }

  let(:recovery_diary_record_1) { double(:recovery_diary_record_1) }
  let(:recovery_diary_record_2) { double(:recovery_diary_record_2) }
  let(:avaliation_recovery_diary_record_1) { double(:avaliation_recovery_diary_record_1) }
  let(:avaliation_recovery_diary_record_2) { double(:avaliation_recovery_diary_record_2) }
  let(:avaliation_1) { create(:avaliation, :with_teacher_discipline_classroom, teacher: teacher) }
  let(:avaliation_2) { create(:avaliation, :with_teacher_discipline_classroom, teacher: teacher) }
  let(:avaliation_3) { create(:avaliation, :with_teacher_discipline_classroom, teacher: teacher) }
  let(:daily_note_1) { create(:daily_note, avaliation: avaliation_1) }
  let(:daily_note_2) { create(:daily_note, avaliation: avaliation_2) }
  let(:daily_note_3) { create(:daily_note, avaliation: avaliation_3) }
  let(:daily_note_student_1) { create(:daily_note_student, student: student, daily_note: daily_note_1) }
  let(:daily_note_student_2) { create(:daily_note_student, student: student, daily_note: daily_note_2) }
  let(:daily_note_student_3) { create(:daily_note_student, student: student, daily_note: daily_note_3) }
  let(:recovery_diary_record_student_1) { double(:recovery_diary_record_student_1) }
  let(:recovery_diary_record_student_2) { double(:recovery_diary_record_student_2) }

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
    stub_recovery_diary_record_1
    stub_recovery_diary_record_2
    stub_daily_note_students
    stub_avaliations
    stub_student_avaliation_exemption_query

    stub_recovery_diary_records
    stub_avaliation_recovery_diary_records
    stub_complementary_exam_calculator
  end

  describe '#calculate' do
    context 'when the calculation type is sum' do
      let(:recovered_note_1) { 9.0 }
      let(:recovered_note_2) { 7.0 }
      let(:sum_calculation_type?) { true }
      let(:daily_note_students) { [daily_note_student_1, daily_note_student_2] }

      before {
        stub_const('TestSettingFetcher', Class.new)
        allow(TestSettingFetcher).to(
          receive(:current).with(classroom, school_calendar_step).and_return(test_setting)
        )
        allow(score_rounder).to receive(:round).with(16.0).and_return(16.0)
      }

      it "should calculate the average correctly" do
        expect(subject.calculate(classroom, discipline, school_calendar_step)).to eq(16.0)
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

      before {
        stub_const('TestSettingFetcher', Class.new)
        allow(TestSettingFetcher).to(
          receive(:current).with(classroom, school_calendar_step).and_return(test_setting)
        )
        allow(score_rounder).to receive(:round).with(9.0).and_return(9.0)
      }

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

      before { allow(score_rounder).to receive(:round).with(7.0).and_return(7.0) }

      it "calculates average using recovery_diary_records without daily_note_student" do
        expect(subject.calculate(classroom, discipline, school_calendar_step)).to eq(7.0)
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

        before { allow(score_rounder).to receive(:round).with(4.5).and_return(4.5) }

        it "calculates average using recovery_diary_records without daily_note_student" do
          expect(subject.calculate(classroom, discipline, school_calendar_step)).to eq(4.5)
        end
      end
    end
    context '#when params are correct' do
      let(:daily_note_students) { [daily_note_student_1, daily_note_student_2, daily_note_student_3] }
      it 'expects to call score_rounder with correct params' do
        expect(ScoreRounder).to receive(:new)
          .with(classroom, RoundedAvaliations::NUMERICAL_EXAM, school_calendar_step)
          .and_return(score_rounder)
          .at_least(:once)

        expect(score_rounder).to receive(:round)
          .with(anything)
          .at_least(:once)

        subject.calculate(classroom, discipline, school_calendar_step)
      end
    end
  end

  def stub_school_calendar_step
    allow(school_calendar_step).to receive(:test_setting).and_return(test_setting)
  end

  def stub_notes_query
    stub_const('StudentNotesQuery', Class.new)
    allow(StudentNotesQuery).to(
      receive(:new).with(student, discipline, classroom, start_at, end_at).and_return(student_notes_query)
    )
    allow(student_notes_query).to receive(:daily_note_students).and_return(daily_note_students)
    allow(student_notes_query).to receive(:recovery_diary_records).and_return(recovery_diary_records)
    allow(student_notes_query).to receive(:recovery_lowest_note_in_step).and_return(recovery_diary_record_1)
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
    allow(test_setting).to receive(:default_division_weight).and_return(1)
  end

  def stub_daily_note_students
    allow(daily_note_student_1).to receive(:recovered_note).and_return(recovered_note_1)
    allow(daily_note_student_2).to receive(:recovered_note).and_return(recovered_note_2)
    allow(daily_note_student_3).to receive(:recovered_note).and_return(recovered_note_3)
  end

  def stub_recovery_diary_record_1
    allow(recovery_diary_record_1).to receive(:students).and_return(students_1)
    allow(recovery_diary_record_1).to receive(:score).and_return(5)
    allow(students_1).to receive(:find_by_student_id).and_return(student_1)
    allow(students_1).to receive(:find_by).and_return(student_1)
    allow(student_1).to receive(:score).and_return(score_1)
  end

  def stub_recovery_diary_record_2
    allow(recovery_diary_record_2).to receive(:students).and_return(students_2)
    allow(recovery_diary_record_2).to receive(:score).and_return(5)
    allow(students_2).to receive(:find_by_student_id).and_return(student_2)
    allow(students_2).to receive(:find_by).and_return(student_2)
    allow(student_2).to receive(:score).and_return(score_2)
  end

  def stub_score_rounder
    stub_const('ScoreRounder', Class.new)
    allow(ScoreRounder).to(
      receive(:new)
      .with(
        classroom,
        RoundedAvaliations::NUMERICAL_EXAM,
        school_calendar_step
      )
      .and_return(score_rounder)
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

  def stub_avaliations
    allow(avaliation_1).to receive(:weight).and_return(weight_avaliation_1)
    allow(avaliation_2).to receive(:weight).and_return(weight_avaliation_2)
    allow(avaliation_3).to receive(:weight).and_return(weight_avaliation_3)
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

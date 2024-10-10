require 'rails_helper'

RSpec.describe ComplementaryExamSetting, type: :model do
  subject(:complementary_exam_setting) { create(:complementary_exam_setting, :with_two_grades, :with_teacher_discipline_classroom) }
  let(:complementary_exam_setting_with_two_grades) {
    create(:complementary_exam_setting, :with_two_grades, :with_teacher_discipline_classroom)
  }
  let(:classrooms_grade) {
    create(
      :classrooms_grade,
      :with_classroom_trimester_steps,
      grade: complementary_exam_setting_with_two_grades.grades.first
    )
  }
  let(:classroom) { classrooms_grade.classroom }
  let(:step) { classroom.calendar.classroom_steps.first }
  let(:complementary_exam) {
    create(
      :complementary_exam,
      :with_teacher_discipline_classroom,
      classroom: classroom,
      recorded_at: Date.current,
      step_id: step.id,
      complementary_exam_setting: complementary_exam_setting_with_two_grades
    )
  }

  describe '.by_grade_id' do
    before do
      complementary_exam_setting_with_two_grades
    end

    context 'invalid grade_id passed' do
      it { expect(described_class.by_grade_id(0).count).to be(0) }
    end

    context 'existing grade_id passed' do
      it { expect(described_class.by_grade_id(complementary_exam_setting_with_two_grades.grade_ids.first).count).to be(1) }
    end
  end

  context 'Validations' do
    it { expect(subject).to validate_presence_of(:description) }
    it { expect(subject).to validate_presence_of(:initials) }
    it { expect(subject).to validate_presence_of(:affected_score) }
    it { expect(subject).to validate_presence_of(:calculation_type) }
    it { expect(subject).to validate_presence_of(:maximum_score) }
    it { expect(subject).to validate_presence_of(:number_of_decimal_places) }
    it { expect(subject).to validate_presence_of(:year) }

    describe '#uniqueness_of_calculation_type_by_grade' do
      context 'calculation type isnt substitution' do
        before do
          subject.calculation_type = CalculationTypes::SUM
        end

        it do
          subject.valid?
          expect(subject.errors.full_messages).to_not include(I18n.t('activerecord.errors.models.complementary_exam_setting.attributes.base.uniqueness_of_calculation_type_by_grade'))
        end
      end
      context 'calculation type is substitution' do
        before do
          subject.calculation_type = CalculationTypes::SUBSTITUTION
        end

        it do
          subject.valid?
          expect(subject.errors.full_messages).to_not include(I18n.t('activerecord.errors.models.complementary_exam_setting.attributes.base.uniqueness_of_calculation_type_by_grade'))
        end

        context 'has the same grades and same affected score of another setting' do
          let(:another_setting) {
            create(
              :complementary_exam_setting,
              :with_two_grades,
              :with_teacher_discipline_classroom,
              calculation_type: CalculationTypes::SUBSTITUTION
            )
          }
          before do
            subject.grade_ids = another_setting.grade_ids
            subject.affected_score = another_setting.affected_score
          end

          it do
            subject.valid?
            expect(subject.errors.full_messages).to include(I18n.t('activerecord.errors.models.complementary_exam_setting.attributes.base.uniqueness_of_calculation_type_by_grade'))
          end
        end
      end
    end

    describe '#grades_in_use_cant_be_removed' do
      context 'is a new record' do
        before do
          subject = described_class.new
        end

        it do
          subject.valid?
          expect(subject.errors.full_messages).to_not include(I18n.t('activerecord.errors.models.complementary_exam_setting.attributes.base.grades_in_use_cant_be_removed'))
        end
      end

      context 'grade that has a classroom in complementary exam is removed' do
        subject do
          complementary_exam_setting_with_two_grades.grade_ids =
            complementary_exam_setting_with_two_grades.grade_ids -
            [complementary_exam.classroom.classrooms_grades.first.grade_id]
          complementary_exam_setting_with_two_grades
        end

        it do
          subject.valid?
          expect(subject.errors.full_messages).to include(I18n.t('activerecord.errors.models.complementary_exam_setting.attributes.base.grades_in_use_cant_be_removed'))
        end
      end

      context 'grade that hasnt a classroom in complementary exam is removed' do

        subject do
          complementary_exam_setting_with_two_grades.grade_ids = [classrooms_grade.grade_id]
          complementary_exam_setting_with_two_grades
        end

        it do
          subject.valid?
          expect(subject.errors.full_messages).to_not include(I18n.t('activerecord.errors.models.complementary_exam_setting.attributes.base.grades_in_use_cant_be_removed'))
        end
      end
    end
  end
end

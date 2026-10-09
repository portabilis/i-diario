require 'rails_helper'

RSpec.describe TestSettingUpdatePolicy do
  describe '.can_update?' do
    context 'when there are no avaliations associated' do
      let(:test_setting) { create(:test_setting, minimum_score: 5, maximum_score: 10) }

      it 'allows any change' do
        test_setting.assign_attributes(
          minimum_score: 8,
          number_of_decimal_places: 1,
          average_calculation_type: AverageCalculationTypes::SUM
        )

        expect(described_class.can_update?(test_setting)).to be true
      end
    end

    context 'when there are avaliations associated with arithmetic calculation type' do
      let(:test_setting) do
        create(:test_setting,
               average_calculation_type: AverageCalculationTypes::ARITHMETIC,
               minimum_score: 6,
               maximum_score: 10,
               number_of_decimal_places: 2)
      end

      before do
        create(:avaliation, :with_teacher_discipline_classroom, test_setting: test_setting)
      end

      context 'when no fields are changed' do
        it 'allows the update' do
          expect(described_class.can_update?(test_setting)).to be true
        end
      end

      context 'when changing minimum_score' do
        it 'allows decreasing minimum_score' do
          test_setting.minimum_score = 3

          expect(described_class.can_update?(test_setting)).to be true
        end

        it 'allows decreasing minimum_score to zero' do
          test_setting.minimum_score = 0

          expect(described_class.can_update?(test_setting)).to be true
        end

        it 'does not allow increasing minimum_score' do
          test_setting.minimum_score = 8

          expect(described_class.can_update?(test_setting)).to be false
        end
      end

      context 'when changing maximum_score' do
        it 'allows increasing maximum_score' do
          test_setting.maximum_score = 100

          expect(described_class.can_update?(test_setting)).to be true
        end

        it 'allows decreasing maximum_score' do
          test_setting.maximum_score = 7

          expect(described_class.can_update?(test_setting)).to be true
        end
      end

      context 'when changing both minimum_score (decrease) and maximum_score' do
        it 'allows the update' do
          test_setting.assign_attributes(minimum_score: 0, maximum_score: 100)

          expect(described_class.can_update?(test_setting)).to be true
        end
      end

      context 'when changing disallowed fields' do
        it 'does not allow changing number_of_decimal_places' do
          test_setting.number_of_decimal_places = 0

          expect(described_class.can_update?(test_setting)).to be false
        end

        it 'does not allow changing average_calculation_type' do
          test_setting.average_calculation_type = AverageCalculationTypes::SUM

          expect(described_class.can_update?(test_setting)).to be false
        end

        it 'does not allow changing exam_setting_type' do
          test_setting.exam_setting_type = ExamSettingTypes::BY_SCHOOL_TERM

          expect(described_class.can_update?(test_setting)).to be false
        end

        it 'does not allow changing default_division_weight' do
          test_setting.default_division_weight = 2

          expect(described_class.can_update?(test_setting)).to be false
        end

        it 'does not allow changing disallowed field even with allowed field' do
          test_setting.assign_attributes(minimum_score: 0, number_of_decimal_places: 1)

          expect(described_class.can_update?(test_setting)).to be false
        end
      end
    end

    context 'when there are avaliations associated with sum calculation type' do
      let(:test_setting) do
        create(:test_setting_with_sum_calculation_type,
               minimum_score: 5,
               maximum_score: 10,
               number_of_decimal_places: 2)
      end

      before do
        create(:avaliation,
               :with_teacher_discipline_classroom,
               test_setting: test_setting,
               test_setting_test: test_setting.tests.first)
      end

      context 'when changing minimum_score' do
        it 'allows decreasing minimum_score' do
          test_setting.minimum_score = 0

          expect(described_class.can_update?(test_setting)).to be true
        end

        it 'does not allow increasing minimum_score' do
          test_setting.minimum_score = 8

          expect(described_class.can_update?(test_setting)).to be false
        end
      end

      context 'when changing maximum_score' do
        it 'allows increasing maximum_score' do
          test_setting.maximum_score = 100

          expect(described_class.can_update?(test_setting)).to be true
        end

        it 'allows decreasing maximum_score' do
          test_setting.maximum_score = 7

          expect(described_class.can_update?(test_setting)).to be true
        end
      end

      context 'when changing disallowed fields' do
        it 'does not allow changing number_of_decimal_places' do
          test_setting.number_of_decimal_places = 0

          expect(described_class.can_update?(test_setting)).to be false
        end
      end
    end

    context 'when changing the scope of a general by school setting' do
      let(:avaliation) { create(:avaliation, :with_teacher_discipline_classroom) }
      let(:covered_grade_ids) { avaliation.grade_ids }
      let(:removable_grade) { create(:grade) }
      let(:removable_unity) { create(:unity) }
      let(:other_unity) { create(:unity) }
      let(:other_grade) { create(:grade) }

      let(:test_setting) do
        create(:test_setting, :general_by_school,
               minimum_score: 5,
               maximum_score: 10,
               number_of_decimal_places: 2,
               unities: [create(:unity).id, removable_unity.id],
               grades: covered_grade_ids + [removable_grade.id]).tap do |setting|
          # not_validate_columns pula a trava de perfil do ColumnsLockable, que exige current_user
          avaliation.not_validate_columns = true
          avaliation.update!(test_setting: setting)
        end
      end

      context 'when widening the scope' do
        it 'allows adding a grade' do
          test_setting.grades += [other_grade.id]

          expect(described_class.can_update?(test_setting)).to be true
        end

        it 'allows adding a unity' do
          test_setting.unities += [other_unity.id]

          expect(described_class.can_update?(test_setting)).to be true
        end

        it 'allows adding a grade and a unity at once' do
          test_setting.assign_attributes(
            grades: test_setting.grades + [other_grade.id],
            unities: test_setting.unities + [other_unity.id]
          )

          expect(described_class.can_update?(test_setting)).to be true
        end

        it 'allows adding a grade while decreasing minimum_score' do
          test_setting.assign_attributes(grades: test_setting.grades + [other_grade.id], minimum_score: 2)

          expect(described_class.can_update?(test_setting)).to be true
        end

        it 'does not allow adding a grade while increasing minimum_score' do
          test_setting.assign_attributes(grades: test_setting.grades + [other_grade.id], minimum_score: 8)

          expect(described_class.can_update?(test_setting)).to be false
        end

        # o controller envia séries e escolas como array de String (split do campo select2)
        it 'allows adding a grade sent as string' do
          test_setting.grades = (test_setting.grades + [other_grade.id]).map(&:to_s)

          expect(described_class.can_update?(test_setting)).to be true
        end

        it 'does not allow adding a grade while changing the score rule' do
          test_setting.assign_attributes(
            grades: test_setting.grades + [other_grade.id],
            number_of_decimal_places: 0
          )

          expect(described_class.can_update?(test_setting)).to be false
        end
      end

      context 'when there are no avaliations associated' do
        let(:free_test_setting) do
          create(:test_setting, :general_by_school, grades: [other_grade.id, removable_grade.id])
        end

        it 'still allows removing a grade' do
          free_test_setting.grades -= [removable_grade.id]

          expect(described_class.can_update?(free_test_setting)).to be true
        end
      end

      context 'when narrowing the scope' do
        it 'does not allow removing a grade' do
          test_setting.grades -= [removable_grade.id]

          expect(described_class.can_update?(test_setting)).to be false
        end

        it 'does not allow removing a unity' do
          test_setting.unities -= [removable_unity.id]

          expect(described_class.can_update?(test_setting)).to be false
        end

        it 'does not allow adding one grade and removing another at once' do
          test_setting.grades = covered_grade_ids + [other_grade.id]

          expect(described_class.can_update?(test_setting)).to be false
        end

        # grades vazio significa "todas as séries": sair desse estado restringe a abrangência
        it 'does not allow replacing all grades with an explicit list' do
          test_setting.update_columns(grades: [])
          test_setting.reload
          test_setting.grades = [other_grade.id]

          expect(described_class.can_update?(test_setting)).to be false
        end

        # o inverso amplia a abrangência, mas passa a alcançar séries que ainda nem existem:
        # a régua exige que as séries sejam nomeadas uma a uma
        it 'does not allow replacing an explicit list with all grades' do
          test_setting.grades = []

          expect(described_class.can_update?(test_setting)).to be false
        end
      end
    end

    context 'when changing tests (TestSettingTest)' do
      let(:test_setting) do
        create(:test_setting_with_sum_calculation_type,
               minimum_score: 5,
               maximum_score: 10)
      end

      let(:test_setting_test) { test_setting.tests.first }

      context 'when tests have avaliations associated' do
        before do
          create(:avaliation,
                 :with_teacher_discipline_classroom,
                 test_setting: test_setting,
                 test_setting_test: test_setting_test)
        end

        it 'allows changing test description' do
          test_setting_test.description = 'New description'

          expect(described_class.can_update?(test_setting)).to be true
        end

        it 'does not allow changing test weight' do
          test_setting_test.weight = 5

          expect(described_class.can_update?(test_setting)).to be false
        end
      end

      context 'when tests have no avaliations associated' do
        it 'allows changing test weight' do
          test_setting_test.weight = 5

          expect(described_class.can_update?(test_setting)).to be true
        end
      end

      context 'when adding a new test' do
        before do
          create(:avaliation,
                 :with_teacher_discipline_classroom,
                 test_setting: test_setting,
                 test_setting_test: test_setting_test)
        end

        it 'allows adding a new test' do
          test_setting.tests.build(description: 'New test', weight: 5)

          expect(described_class.can_update?(test_setting)).to be true
        end
      end
    end
  end
end

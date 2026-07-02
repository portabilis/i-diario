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

require 'rails_helper'

RSpec.describe FeaturesAccessLevels, type: :service do
  describe '.teacher_features' do
    subject { described_class.teacher_features }

    it { is_expected.to include(:copy_discipline_teaching_plan) }
    it { is_expected.to include(:copy_knowledge_area_teaching_plan) }
  end

  describe '.administrator_features' do
    subject { described_class.administrator_features }

    it 'includes both copy teaching plan features' do
      is_expected.to include(:copy_discipline_teaching_plan, :copy_knowledge_area_teaching_plan)
    end
  end

  describe '.employee_features' do
    subject { described_class.employee_features }

    it 'includes both copy teaching plan features' do
      is_expected.to include(:copy_discipline_teaching_plan, :copy_knowledge_area_teaching_plan)
    end
  end
end

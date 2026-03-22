require 'rails_helper'

RSpec.describe FeaturesAccessLevels do
  describe '.administrator_features' do
    it 'inclui maintenance_adjustments nas permissoes de administrador' do
      expect(described_class.administrator_features).to include(:maintenance_adjustments)
    end
  end

  describe '.employee_features' do
    it 'mantem maintenance_adjustments restrito a administradores' do
      expect(described_class.employee_features).not_to include(:maintenance_adjustments)
    end
  end
end

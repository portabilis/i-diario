require 'rails_helper'

RSpec.describe DateValidation, type: :model do
  subject(:controller_class) do
    Class.new do
      include DateValidation

      # Os métodos do concern são privados; o teste os expõe para poder chamá-los direto.
      public :valid_date?, :parse_date
    end.new
  end

  # Data que existe no formato mas não no calendário (junho não tem dia 31).
  let(:nonexistent_date) { '31/06/2026' }
  # Sequência que nem chega a casar com o formato de data.
  let(:unparseable_date) { '70/82/026_' }

  describe '#valid_date?' do
    it 'returns true for an existing date' do
      expect(controller_class.valid_date?('15/06/2026')).to eq(true)
    end

    it 'returns false for a nonexistent day' do
      expect(controller_class.valid_date?(nonexistent_date)).to eq(false)
    end

    it 'returns false for a nonexistent month' do
      expect(controller_class.valid_date?('15/13/2026')).to eq(false)
    end

    it 'returns false for an unparseable date' do
      expect(controller_class.valid_date?(unparseable_date)).to eq(false)
    end

    it 'returns false when the date is an empty string' do
      expect(controller_class.valid_date?('')).to eq(false)
    end

    it 'returns false when the date is nil' do
      expect(controller_class.valid_date?(nil)).to eq(false)
    end
  end

  describe '#parse_date' do
    it 'returns the parsed date for an existing date' do
      expect(controller_class.parse_date('15/06/2026')).to eq(Date.new(2026, 6, 15))
    end

    it 'returns nil for a nonexistent day' do
      expect(controller_class.parse_date(nonexistent_date)).to be_nil
    end

    it 'returns nil for an unparseable date' do
      expect(controller_class.parse_date(unparseable_date)).to be_nil
    end

    it 'returns nil when the date is an empty string' do
      expect(controller_class.parse_date('')).to be_nil
    end

    it 'returns nil when the date is nil' do
      expect(controller_class.parse_date(nil)).to be_nil
    end

    # Uma requisição pode trazer o parâmetro como array ou hash ("?data[]=x"). Sem
    # tratamento o to_date levantaria NoMethodError, que escaparia do rescue.
    it 'returns nil when the param is not a string' do
      expect(controller_class.parse_date(['15/06/2026'])).to be_nil
      expect(controller_class.parse_date('x' => '1')).to be_nil
      expect(controller_class.parse_date(15)).to be_nil
    end

    it 'does not raise when the param is not a string' do
      expect { controller_class.parse_date(['15/06/2026']) }.not_to raise_error
    end
  end

  # Os controllers abaixo chamam valid_date?/parse_date no caminho de tratamento da data.
  # Sem o include, a chamada só falharia em produção: nenhum outro spec cobre esse vínculo.
  describe 'controllers that consume the concern' do
    [
      AbsenceJustificationReportController,
      AbsenceJustificationsController,
      AttendanceRecordReportController,
      AvaliationRecoveryLowestNotesController,
      ConceptualExamsController,
      DailyFrequenciesInBatchsController,
      DisciplineLessonPlanReportController,
      KnowledgeAreaLessonPlanReportController,
      ObservationRecordReportController,
      SchoolCalendarEventsController
    ].each do |controller|
      it "#{controller} has the concern available" do
        expect(controller.private_method_defined?(:valid_date?)).to eq(true)
        expect(controller.private_method_defined?(:parse_date)).to eq(true)
      end
    end
  end
end

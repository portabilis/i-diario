require 'rails_helper'

RSpec.describe InfrequencyTracking, type: :model do
  describe '#absence_dates' do
    def absence_dates(notification_data)
      described_class.new(notification_data: notification_data).absence_dates
    end

    it 'returns the distinct dates in ascending order' do
      expect(absence_dates([{ 'teacher_id' => 1, 'absences' => %w[2026-06-03 2026-06-01] }]))
        .to eq(%w[2026-06-01 2026-06-03])
    end

    # O mesmo dia aparece uma vez por professor que registrou a falta.
    it 'counts a day once when more than one teacher registered the absence' do
      data = [
        { 'teacher_id' => 1, 'absences' => %w[2026-06-01 2026-06-02] },
        { 'teacher_id' => 2, 'absences' => %w[2026-06-02] }
      ]

      expect(absence_dates(data)).to eq(%w[2026-06-01 2026-06-02])
    end

    # Antes de persistir, o notifier monta o hash com chaves símbolo.
    it 'reads symbol keys as well' do
      expect(absence_dates([{ teacher_id: 1, absences: %w[2026-06-01] }])).to eq(%w[2026-06-01])
    end

    it 'ignores entries out of shape instead of failing' do
      data = [{ 'teacher_id' => 1 }, 'garbage', nil, { 'teacher_id' => 2, 'absences' => %w[2026-06-05] }]

      expect(absence_dates(data)).to eq(%w[2026-06-05])
    end

    it 'reads a single hash as one entry' do
      expect(absence_dates('teacher_id' => 1, 'absences' => %w[2026-06-01])).to eq(%w[2026-06-01])
    end

    it 'returns an empty list when there is no data' do
      expect(absence_dates(nil)).to eq([])
    end
  end
end

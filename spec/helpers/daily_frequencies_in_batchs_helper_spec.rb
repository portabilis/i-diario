# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DailyFrequenciesInBatchsHelper, type: :helper do
  # Aluno rematriculado: mesma matrícula de aluno (student_id), duas enturmações —
  # uma encerrada (saiu) e uma em aberto (voltou). Cada uma vira uma linha em @students.
  let(:student_id) { 50_183 }

  let(:active_row) do
    { student: { id: student_id, name: 'Geovana' }, joined_at: '2026-04-27', left_at: '' }
  end

  let(:closed_row) do
    { student: { id: student_id, name: 'Geovana' }, joined_at: '2026-01-19', left_at: '2026-02-25' }
  end

  let(:inactive_data) do
    [
      { date: Date.new(2026, 4, 27), student_id: student_id, status: :inactive },
      { date: Date.new(2026, 4, 28), student_id: student_id, status: :inactive }
    ]
  end

  describe '#inactive_badge_for?' do
    it 'returns false for the active (open) enrollment row' do
      expect(helper.inactive_badge_for?(active_row, inactive_data)).to eq(false)
    end

    it 'returns true for the closed enrollment row' do
      expect(helper.inactive_badge_for?(closed_row, inactive_data)).to eq(true)
    end

    it 'returns false when there is no inactive entry for the student' do
      dependence_data = [{ date: Date.new(2026, 4, 27), student_id: student_id, status: :dependence }]

      expect(helper.inactive_badge_for?(closed_row, dependence_data)).to eq(false)
    end
  end

  describe '#student_statuses_for' do
    before do
      helper.instance_variable_set(:@additional_data, inactive_data)
    end

    it 'does not flag the active enrollment row as inactive' do
      expect(helper.student_statuses_for(active_row)[:inactive]).to eq(false)
    end

    it 'flags the closed enrollment row as inactive' do
      expect(helper.student_statuses_for(closed_row)[:inactive]).to eq(true)
    end

    it 'exposes the other statuses for the row' do
      helper.instance_variable_set(:@additional_data, [
                                     { date: Date.new(2026, 4, 27), student_id: student_id, status: :dependence }
                                   ])

      statuses = helper.student_statuses_for(active_row)

      expect(statuses).to include(
        name: 'Geovana',
        inactive: false,
        dependence: true,
        exempted_from_discipline: false,
        in_active_search: false
      )
    end
  end
end

require 'rails_helper'

RSpec.describe StudentEnrollmentClassroom, type: :model do
  describe '#active_on_date?' do
    let(:date) { Date.new(2026, 6, 1) }

    context 'when joined on or before the date and has not left' do
      it 'returns true' do
        enrollment = described_class.new(joined_at: '2026-01-01', left_at: '')

        expect(enrollment.active_on_date?(date)).to eq(true)
      end
    end

    context 'when joined on or before the date and left after the date' do
      it 'returns true' do
        enrollment = described_class.new(joined_at: '2026-01-01', left_at: '2026-12-01')

        expect(enrollment.active_on_date?(date)).to eq(true)
      end
    end

    context 'when joined after the date' do
      it 'returns false' do
        enrollment = described_class.new(joined_at: '2026-07-01', left_at: '')

        expect(enrollment.active_on_date?(date)).to eq(false)
      end
    end

    context 'when left on or before the date' do
      it 'returns false' do
        enrollment = described_class.new(joined_at: '2026-01-01', left_at: '2026-03-01')

        expect(enrollment.active_on_date?(date)).to eq(false)
      end
    end

    context 'when left exactly on the date' do
      it 'returns false' do
        enrollment = described_class.new(joined_at: '2026-01-01', left_at: '2026-06-01')

        expect(enrollment.active_on_date?(date)).to eq(false)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe FinalRecoveryDiaryRecord, type: :model do
  let(:current_user) { create(:user) }

  subject(:final_recovery_diary_record) { build(:final_recovery_diary_record) }

  before do
    current_user.current_classroom_id = subject.classroom_id
    current_user.current_discipline_id = subject.discipline_id
    allow(subject.recovery_diary_record).to receive(:current_user).and_return(current_user)
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:recovery_diary_record) }
    it { expect(subject).to belong_to(:school_calendar) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:recovery_diary_record) }
    it { expect(subject).to validate_presence_of(:school_calendar) }
  end

  # Salvar a recuperação final com a data em branco quebrava com NoMethodError. Sem data
  # não há etapa correspondente, então o registro é recusado por não estar na última
  # etapa — o que importa aqui é que o erro chega como validação, e não como exceção.
  describe '#recorded_at_must_be_in_last_school_calendar_step' do
    let(:error_key) { 'activerecord.errors.models.final_recovery_diary_record.attributes.recovery_diary_record' }

    before { final_recovery_diary_record.recovery_diary_record.recorded_at = nil }

    it 'adds a validation error instead of raising NoMethodError' do
      expect { final_recovery_diary_record.valid? }.not_to raise_error

      expect(final_recovery_diary_record.errors[:recovery_diary_record]).to include(
        I18n.t("#{error_key}.recorded_at_must_be_in_last_school_calendar_step")
      )
    end
  end
end

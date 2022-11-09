require 'rails_helper'

RSpec.describe ContentRecord, type: :model do
  let(:current_school_calendar_fetcher) { create(:school_calendar, :with_one_step) }

  subject {
    build(
      :content_record,
      :with_contents
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:teacher) }
    it { expect(subject).to have_one(:discipline_content_record) }
    it { expect(subject).to have_one(:knowledge_area_content_record) }
    it { expect(subject).to have_many(:content_records_contents) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:classroom) }
    it { expect(subject).to validate_presence_of(:record_date) }

    it 'should validate if record_date is today or before today' do
      allow(subject).to receive(:school_calendar).and_return(current_school_calendar_fetcher)
      today = Date.current
      subject.record_date = today + 1.day

      expect(subject).to_not be_valid
      expect(
        subject.errors.messages[:record_date]
      ).to include("deve ser igual ou antes de #{today.strftime('%d/%m/%Y')}")
    end

    it 'should validate if there is at least one content id' do
      expect(subject).to_not be_valid
      expect(subject.errors.full_messages).to include('Conteúdos Ao menos um conteúdo deve ser selecionado')
    end

    it 'should validate daily_activities_record if set to be always required' do
      GeneralConfiguration.current
                          .update(require_daily_activities_record: RequireDailyActivitiesRecordTypes::ALWAYS)
      expect(subject).to validate_presence_of(:daily_activities_record)
    end

    it 'should not validate daily_activities_record if set to be not required' do
      GeneralConfiguration.current
                          .update(require_daily_activities_record: RequireDailyActivitiesRecordTypes::DOES_NOT_REQUIRE)
      expect(subject).to_not validate_presence_of(:daily_activities_record)
    end

    context 'required only for discipline content record' do
      before(:each) do
        GeneralConfiguration.current
                            .update(
                              require_daily_activities_record:
                                RequireDailyActivitiesRecordTypes::ON_DISCIPLINE_CONTENT_RECORDS
                            )
      end

      it 'should validate if created by discipline content record' do
        subject.creator_type = 'discipline_content_record'
        expect(subject).to validate_presence_of(:daily_activities_record)
      end

      it 'should not validate if created by knowledge area record' do
        subject.creator_type = 'knowledge_area_content_record'
        expect(subject).to_not validate_presence_of(:daily_activities_record)
      end
    end

    context 'required only for knowledge area content record' do
      before(:each) do
        GeneralConfiguration.current
                            .update(
                              require_daily_activities_record:
                                RequireDailyActivitiesRecordTypes::ON_KNOWLEDGE_AREA_CONTENT_RECORDS
                            )
      end

      it 'should validate if created by knowledge area record' do
        subject.creator_type = 'knowledge_area_content_record'
        expect(subject).to validate_presence_of(:daily_activities_record)
      end

      it 'should not validate if created by discipline content record' do
        subject.creator_type = 'discipline_content_record'
        expect(subject).to_not validate_presence_of(:daily_activities_record)
      end
    end
  end
end

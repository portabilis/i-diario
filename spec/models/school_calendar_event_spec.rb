# encoding: utf-8

require 'rails_helper'

RSpec.describe SchoolCalendarEvent, type: :model do
  subject { SchoolCalendarEvent.new(event_type: event_type) }

  let(:event_type) { nil }

  describe 'associations' do
    it { expect(subject).to belong_to(:school_calendar) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:start_date) }
    it { expect(subject).to validate_presence_of(:end_date) }
    it { expect(subject).to validate_presence_of(:description) }
    it { expect(subject).to validate_presence_of(:event_type) }
    
    context 'when :event_type is :extra_school' do
      let(:event_type) { EventTypes::EXTRA_SCHOOL }

      it { expect(subject).not_to validate_presence_of(:legend) }
    end

    context 'when :event_type is :no_school_with_frequency' do
      let(:event_type) { EventTypes::NO_SCHOOL_WITH_FREQUENCY }

      it { expect(subject).not_to validate_presence_of(:legend) }
    end

    context 'when :event_type is :no_school' do
      let(:event_type) { EventTypes::NO_SCHOOL }

      it { expect(subject).to validate_presence_of(:legend) }
    end

    context 'when :event_type is :extra_school_without_frequency' do
      let(:event_type) { EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY }

      it { expect(subject).to validate_presence_of(:legend) }
    end
  end
end
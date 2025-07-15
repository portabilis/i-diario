# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyNotesController, 'retry logic' do
  let(:controller) { DailyNotesController.new }
  let(:daily_note) { instance_double(DailyNote, id: 1) }

  before do
    allow(controller).to receive(:params).and_return(
      ActionController::Parameters.new(id: 1, daily_note: { students_attributes: {} })
    )
    allow(controller).to receive(:authorize)
    allow(controller).to receive(:destroy_students_not_found)
    allow(controller).to receive(:check_duplicate_enrolled_students)
    allow(controller).to receive(:reload_students_list)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:render)
    allow(controller).to receive(:resource_params).and_return(
      ActionController::Parameters.new(students_attributes: {}).permit!
    )
    allow(controller).to receive(:flash).and_return(ActionDispatch::Flash::FlashHash.new)
    allow(controller).to receive(:daily_notes_path).and_return('/daily_notes')
    
    allow(DailyNote).to receive(:find).and_return(daily_note)
    allow(daily_note).to receive(:localized).and_return(daily_note)
    allow(daily_note).to receive(:assign_attributes)
    allow(daily_note).to receive(:reload)
  end

  describe '#update retry logic' do
    it 'retries once on unique constraint violation then succeeds' do
      save_call_count = 0
      
      allow(daily_note).to receive(:save) do
        save_call_count += 1
        if save_call_count == 1
          raise ActiveRecord::RecordNotUnique.new(
            "PG::UniqueViolation: duplicate key value violates unique constraint \"idx_unique_daily_note_students_active_not_discarded\""
          )
        else
          true
        end
      end

      controller.send(:update)
      
      expect(save_call_count).to eq(2)
      expect(daily_note).to have_received(:reload).once
      expect(daily_note).to have_received(:assign_attributes).exactly(2).times
    end

    it 'does not retry more than once on constraint violation' do
      save_call_count = 0
      
      allow(daily_note).to receive(:save) do
        save_call_count += 1
        raise ActiveRecord::RecordNotUnique.new(
          "PG::UniqueViolation: duplicate key value violates unique constraint \"idx_unique_daily_note_students_active_not_discarded\""
        )
      end

      controller.send(:update)
      
      expect(save_call_count).to eq(2)
      expect(daily_note).to have_received(:reload).once
      expect(controller).to have_received(:render).with(:edit)
    end

    it 'does not retry for other unique constraint violations' do
      save_call_count = 0
      
      allow(daily_note).to receive(:save) do
        save_call_count += 1
        raise ActiveRecord::RecordNotUnique.new(
          "PG::UniqueViolation: duplicate key value violates unique constraint \"some_other_constraint\""
        )
      end

      controller.send(:update)
      
      expect(save_call_count).to eq(1)
      expect(daily_note).not_to have_received(:reload)
      expect(controller).to have_received(:render).with(:edit)
    end
  end
end
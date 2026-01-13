# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyNotesController, 'unique constraint handling' do
  let(:controller) { DailyNotesController.new }
  let(:daily_note) { instance_double(DailyNote, id: 1) }
  let(:flash) { ActionDispatch::Flash::FlashHash.new }

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
    allow(controller).to receive(:flash).and_return(flash)
    allow(controller).to receive(:daily_notes_path).and_return('/daily_notes')
    
    allow(DailyNote).to receive(:find).and_return(daily_note)
    allow(daily_note).to receive(:localized).and_return(daily_note)
    allow(daily_note).to receive(:assign_attributes)
    allow(daily_note).to receive(:reload)
  end

  describe '#update unique constraint handling' do
    it 'shows user-friendly message and reloads data on student constraint violation' do
      allow(daily_note).to receive(:save).and_raise(
        ActiveRecord::RecordNotUnique.new(
          "PG::UniqueViolation: duplicate key value violates unique constraint \"idx_unique_daily_note_students_active_not_discarded\""
        )
      )

      controller.send(:update)
      
      expect(flash[:alert]).to eq("Provavelmente os dados já foram salvos em outra aba. Verifique os valores e salve novamente.")
      expect(daily_note).to have_received(:reload).once
      expect(controller).to have_received(:reload_students_list).once
      expect(controller).to have_received(:render).with(:edit)
    end

    it 'handles other unique constraint violations with generic message' do
      allow(daily_note).to receive(:save).and_raise(
        ActiveRecord::RecordNotUnique.new(
          "PG::UniqueViolation: duplicate key value violates unique constraint \"some_other_constraint\""
        )
      )

      controller.send(:update)
      
      expect(flash[:alert]).to eq("Houve um problema ao salvar. Por favor, tente novamente.")
      expect(daily_note).not_to have_received(:reload)
      expect(controller).to have_received(:reload_students_list).once
      expect(controller).to have_received(:render).with(:edit)
    end

    it 'saves successfully when no constraint violation occurs' do
      allow(daily_note).to receive(:save).and_return(true)

      controller.send(:update)
      
      expect(daily_note).not_to have_received(:reload)
      expect(controller).to have_received(:respond_with)
      expect(flash[:alert]).to be_nil
    end
  end
end
# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe DescriptiveExamStudentPresenter do
  # Prioridade do badge: active_search > inativo (if inactive_student) > dependência > dispensa da disciplina
  def badge_for(attrs)
    defaults = {
      in_active_search: false, inactive_student: false,
      dependence: false, exempted_from_discipline: false
    }
    described_class.new(OpenStruct.new(defaults.merge(attrs)), nil).status_badge
  end

  describe '#status_badge' do
    it 'returns nil when the student has no special situation' do
      expect(badge_for({})).to be_nil
    end

    it 'gives active_search the highest priority' do
      expect(
        badge_for(in_active_search: true, inactive_student: true,
                  dependence: true, exempted_from_discipline: true)
      ).to eq(:active_search)
    end

    it 'returns :inactive when not in active search and the student is inactive' do
      expect(badge_for(inactive_student: true, dependence: true, exempted_from_discipline: true)).to eq(:inactive)
    end

    it 'returns :dependence before exempted_from_discipline' do
      expect(badge_for(dependence: true, exempted_from_discipline: true)).to eq(:dependence)
    end

    it 'returns :exempted_from_discipline when it is the only situation' do
      expect(badge_for(exempted_from_discipline: true)).to eq(:exempted_from_discipline)
    end
  end

  describe '#student_name' do
    it 'formats as "api_code - student"' do
      student = Struct.new(:api_code) { def to_s; 'Maria Silva'; end }.new('123')
      presenter = described_class.new(OpenStruct.new(student: student), nil)

      expect(presenter.student_name).to eq('123 - Maria Silva')
    end
  end
end

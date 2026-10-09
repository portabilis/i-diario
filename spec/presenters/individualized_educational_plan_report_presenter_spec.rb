require 'rails_helper'

RSpec.describe IndividualizedEducationalPlanReportPresenter, type: :presenter do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  before do
    allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
    allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))
  end

  let(:plan) { create(:individualized_educational_plan, characterization: 'Perfil do estudante') }

  describe '.from_record and .from_snapshot parity' do
    it 'renders the same key values for the living plan and for a published version' do
      review_date = create(:iep_review_date, iep: plan, review_date: Date.current)
      create(:iep_curricular_planning, iep: plan, iep_review_date: review_date,
             discipline: create(:discipline, description: 'Matemática'), long_term_goal: 'Meta anual')

      from_record = described_class.from_record(plan)
      version = IndividualizedEducationalPlanPublisher.publish!(plan, name: 'Versão 1',
                                                                published_by: create(:user), classroom: create(:classroom))
      from_snapshot = described_class.from_snapshot(version.reload.content)

      expect(from_record.identification['student_name']).to eq(plan.student.name)
      expect(from_snapshot.identification['student_name']).to eq(plan.student.name)
      expect(from_record.characterization['characterization']).to eq('Perfil do estudante')
      expect(from_snapshot.characterization['characterization']).to eq('Perfil do estudante')

      record_line = from_record.curricular_plannings_by_review.first.last.first
      snapshot_line = from_snapshot.curricular_plannings_by_review.first.last.first
      expect(record_line['component_name']).to eq('Matemática')
      expect(snapshot_line['component_name']).to eq('Matemática')
      expect(snapshot_line['long_term_goal']).to eq('Meta anual')
    end
  end

  describe '#curricular_plannings_by_review' do
    it 'groups by review (chronological) and sorts components alphabetically' do
      first_review = create(:iep_review_date, iep: plan, review_date: Date.current)
      second_review = create(:iep_review_date, iep: plan, review_date: Date.current + 30)
      create(:iep_curricular_planning, iep: plan, iep_review_date: first_review,
             discipline: create(:discipline, description: 'Matemática'))
      create(:iep_curricular_planning, iep: plan, iep_review_date: first_review,
             discipline: create(:discipline, description: 'Arte'))
      create(:iep_curricular_planning, iep: plan, iep_review_date: second_review,
             discipline: create(:discipline, description: 'Ciências'))

      groups = described_class.from_record(plan).curricular_plannings_by_review

      expect(groups.map { |review, _| review.first }).to eq([1, 2])
      expect(groups.first.last.map { |line| line['component_name'] }).to eq(['Arte', 'Matemática'])
      expect(groups.last.last.map { |line| line['component_name'] }).to eq(['Ciências'])
    end
  end

  describe '#filled?' do
    subject(:presenter) { described_class.from_snapshot({}) }

    it 'detects blank and filled values' do
      expect(presenter.filled?(nil)).to eq(false)
      expect(presenter.filled?('')).to eq(false)
      expect(presenter.filled?([])).to eq(false)
      expect(presenter.filled?([''])).to eq(false)
      expect(presenter.filled?('texto')).to eq(true)
      expect(presenter.filled?(['badge'])).to eq(true)
    end
  end

  describe '#localized_date' do
    subject(:presenter) { described_class.from_snapshot({}) }

    it 'formats a Date object (living plan / from_record)' do
      expect(presenter.localized_date(Date.new(2026, 3, 25))).to eq('25/03/2026')
    end

    it 'formats an ISO string (version snapshot / from_snapshot)' do
      expect(presenter.localized_date('2026-03-25')).to eq('25/03/2026')
    end

    it 'returns non-date text unchanged (unity/classroom/guardians are not dates)' do
      expect(presenter.localized_date('Escola Municipal 15 de Novembro')).to eq('Escola Municipal 15 de Novembro')
      expect(presenter.localized_date('Maria Silva')).to eq('Maria Silva')
    end

    it 'returns blank values unchanged' do
      expect(presenter.localized_date(nil)).to be_nil
      expect(presenter.localized_date('')).to eq('')
    end
  end
end

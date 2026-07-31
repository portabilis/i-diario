require 'rails_helper'

RSpec.describe IndividualizedEducationalPlanPublisher, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  # O snapshot congela os responsáveis via i-Educar; em teste a chamada externa é stubada
  # (em produção a url existe e uma indisponibilidade real é tratada com rescue no prefill).
  before do
    allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
    allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))
  end

  let(:user) { create(:user) }
  let(:plan) { create(:individualized_educational_plan, annual_report: 'Relatório do ano') }

  describe '.publish!' do
    it 'creates an active version with name, author and publication time' do
      version = described_class.publish!(plan, name: 'Versão 1', published_by: user)

      expect(version.reload.active).to eq(true)
      expect(version.name).to eq('Versão 1')
      expect(version.published_by).to eq(user)
      expect(version.published_at).to be_present
      expect(plan.reload.finalized_at.to_i).to eq(version.published_at.to_i)
    end

    it 'deactivates the previous version keeping both in the history' do
      first = described_class.publish!(plan, name: 'Versão 1', published_by: user)
      second = described_class.publish!(plan, name: 'Versão 2', published_by: user)

      expect(plan.iep_versions.count).to eq(2)
      expect(first.reload.active).to eq(false)
      expect(second.reload.active).to eq(true)
      expect(plan.reload.active_version).to eq(second)
    end

    it 'does not publish without a version name' do
      expect {
        described_class.publish!(plan, name: '', published_by: user)
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(plan.iep_versions.count).to eq(0)
      expect(plan.reload.finalized_at).to be_nil
    end

    it 'rolls back and raises when a line references a review date from another plan' do
      review_date = create(:iep_review_date, iep: plan, review_date: Date.current)
      planning = create(:iep_curricular_planning, iep: plan, iep_review_date: review_date,
                                                  long_term_goal: 'Meta')

      foreign_review_date = create(:iep_review_date, review_date: Date.current)
      planning.update_column(:iep_review_date_id, foreign_review_date.id)

      expect {
        described_class.publish!(plan, name: 'Versão 1', published_by: user)
      }.to raise_error(ArgumentError, /não pertence ao plano/)

      expect(plan.iep_versions.count).to eq(0)
    end

    it 'never mutates the content of a previously published version' do
      first = described_class.publish!(plan, name: 'Versão 1', published_by: user)
      original_content = first.content.deep_dup

      plan.update!(annual_report: 'Relatório alterado depois')
      described_class.publish!(plan, name: 'Versão 2', published_by: user)

      expect(first.reload.content).to eq(original_content)
      expect(first.content['final_evaluation']['annual_report']).to eq('Relatório do ano')
    end

    describe 'snapshot content' do
      it 'stores resolved names for identification and final evaluation' do
        version = described_class.publish!(plan, name: 'Versão 1', published_by: user)

        identification = version.content['identification']
        expect(identification['student_name']).to eq(plan.student.name)
        expect(identification['classroom_name']).to eq(plan.classroom.description)
        expect(identification['teacher_name']).to eq(plan.teacher.name)
        expect(version.content['final_evaluation']['annual_report']).to eq('Relatório do ano')
      end

      it 'stores option descriptions of the multi-selects' do
        option = create(:iep_option, :communication_profile, description: 'Comunicação funcional')
        plan.communication_profile_option_ids = [option.id]
        plan.save!

        version = described_class.publish!(plan, name: 'Versão 1', published_by: user)

        expect(version.content['characterization']['communication_profile'])
          .to eq(['Comunicação funcional'])
      end

      it 'stores section 4 lines with review number, component name and accommodations' do
        review_date = create(:iep_review_date, iep: plan, review_date: Date.current)
        discipline = create(:discipline, description: 'Matemática')
        accommodation = create(:iep_option, :instructional_accommodation, description: 'Uso de materiais concretos')
        planning = create(:iep_curricular_planning, iep: plan, iep_review_date: review_date,
                                                    discipline: discipline, long_term_goal: 'Meta anual')
        planning.instructional_accommodation_option_ids = [accommodation.id]
        planning.save!

        version = described_class.publish!(plan, name: 'Versão 1', published_by: user)

        line = version.content['curricular_plannings'].first
        expect(line['review_number']).to eq(1)
        expect(line['component_type']).to eq('discipline')
        expect(line['component_name']).to eq('Matemática')
        expect(line['long_term_goal']).to eq('Meta anual')
        expect(line['instructional_accommodations']).to eq(['Uso de materiais concretos'])
      end
    end
  end
end

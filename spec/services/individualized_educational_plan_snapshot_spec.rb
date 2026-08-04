require 'rails_helper'

# Estrutura canônica congelada de um PEI. O foco aqui são os campos de identificação vindos do
# prefill (birth_date/guardians/diagnosis/shift) — comportamento novo do snapshot e o de maior
# risco (é o que a versão publicada congela para sempre). O restante do conteúdo (nomes, opções,
# seções 4/5) é coberto pelo publisher_spec.
RSpec.describe IndividualizedEducationalPlanSnapshot, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:plan) { create(:individualized_educational_plan) }

  describe '.build identification' do
    it 'freezes the student data fields from the prefill' do
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data)
        .with(plan.student, classroom: nil)
        .and_return(birth_date: '10/03/2015', guardians: 'Maria e João',
                    guardians_unavailable: false, diagnosis: 'TEA', shift: 'Matutino')

      identification = described_class.build(plan)['identification']

      expect(identification['birth_date']).to eq('10/03/2015')
      expect(identification['guardians']).to eq('Maria e João')
      expect(identification['guardians_unavailable']).to eq(false)
      expect(identification['diagnosis']).to eq('TEA')
      expect(identification['shift']).to eq('Matutino')
    end

    it 'records guardians as unavailable when i-Educar could not be reached' do
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data)
        .and_return(birth_date: nil, guardians: nil, guardians_unavailable: true,
                    diagnosis: nil, shift: nil)

      identification = described_class.build(plan)['identification']

      expect(identification['guardians']).to be_nil
      expect(identification['guardians_unavailable']).to eq(true)
    end

    it 'uses the prefetched student_data instead of calling the prefill' do
      expect(IndividualizedEducationalPlanPrefill).not_to receive(:student_data)
      prefetched = { birth_date: '01/01/2015', guardians: 'Responsável X',
                     guardians_unavailable: false, diagnosis: nil, shift: 'Vespertino' }

      identification = described_class.build(plan, student_data: prefetched)['identification']

      expect(identification['guardians']).to eq('Responsável X')
      expect(identification['shift']).to eq('Vespertino')
    end
  end
end

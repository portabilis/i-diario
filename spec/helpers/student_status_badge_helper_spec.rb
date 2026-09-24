require 'rails_helper'

RSpec.describe StudentStatusBadgeHelper, type: :helper do
  describe '#student_status_badge' do
    context 'when status is :dependence' do
      it 'renders badge with dependence modifier and label' do
        result = helper.student_status_badge(:dependence)

        expect(result).to include('badge-status badge-status--dependence')
        expect(result).to include('title="Aluno cursando dependência"')
        expect(result).to include('Dependência')
      end
    end

    context 'when status is :exempted' do
      it 'renders badge with exempted modifier and label' do
        result = helper.student_status_badge(:exempted)

        expect(result).to include('badge-status badge-status--exempted')
        expect(result).to include('title="Aluno dispensado da avaliação"')
        expect(result).to include('Dispensado')
      end
    end

    context 'when status is :inactive' do
      it 'renders badge with inactive modifier and label' do
        result = helper.student_status_badge(:inactive)

        expect(result).to include('badge-status badge-status--inactive')
        expect(result).to include('title="Aluno não enturmado"')
        expect(result).to include('Não enturmado')
      end
    end

    context 'when status is :exempted_from_discipline' do
      it 'renders badge with exempted-from-discipline modifier and label' do
        result = helper.student_status_badge(:exempted_from_discipline)

        expect(result).to include('badge-status badge-status--exempted-from-discipline')
        expect(result).to include('title="Aluno dispensado da disciplina"')
        expect(result).to include('Dispensado')
      end
    end

    context 'when status is :active_search' do
      it 'renders badge with active-search modifier and label' do
        result = helper.student_status_badge(:active_search)

        expect(result).to include('badge-status badge-status--active-search')
        expect(result).to include('title="Aluno em busca ativa"')
        expect(result).to include('Busca Ativa')
      end
    end
  end
end

require 'rails_helper'

RSpec.describe IeducarApi::InfoMessageBuilder, type: :service do
  let(:info) { {} }
  let(:builder) { described_class.new(info) }

  # Mocks para os modelos
  let(:student) { double('Student', name: 'João Silva') }
  let(:discipline) { double('Discipline', description: 'Matemática') }
  let(:classroom) { double('Classroom', description: '1º Ano A') }

  describe '#initialize' do
    it 'sets the info hash' do
      service = described_class.new(info)
      expect(service.send(:info)).to eq(info)
    end

    it 'initializes cache hashes' do
      service = described_class.new(info)
      expect(service.send(:students_cache)).to eq({})
      expect(service.send(:disciplines_cache)).to eq({})
      expect(service.send(:classrooms_cache)).to eq({})
    end
  end

  describe '#build' do
    context 'when info is empty' do
      let(:info) { {} }

      it 'returns empty string' do
        expect(builder.build).to eq('')
      end
    end

    context 'when info contains only classroom' do
      let(:info) { { 'classroom' => '123' } }

      before do
        allow(Classroom).to receive(:find_by).with(api_code: '123').and_return(classroom)
      end

      it 'returns classroom information' do
        expect(builder.build).to eq('Turma: 1º Ano A;<br>')
      end
    end

    context 'when info contains only student' do
      let(:info) { { 'student' => '456' } }

      before do
        allow(Student).to receive(:find_by).with(api_code: '456').and_return(student)
      end

      it 'returns student information' do
        expect(builder.build).to eq('Aluno: João Silva;<br>')
      end
    end

    context 'when info contains only discipline' do
      let(:info) { { 'discipline' => '789' } }

      before do
        allow(Discipline).to receive(:find_by).with(api_code: '789').and_return(discipline)
      end

      it 'returns discipline information' do
        expect(builder.build).to eq('Componente curricular: Matemática;<br>')
      end
    end

    context 'when info contains all fields' do
      let(:info) do
        {
          'classroom' => '123',
          'student' => '456',
          'discipline' => '789'
        }
      end

      before do
        allow(Classroom).to receive(:find_by).with(api_code: '123').and_return(classroom)
        allow(Student).to receive(:find_by).with(api_code: '456').and_return(student)
        allow(Discipline).to receive(:find_by).with(api_code: '789').and_return(discipline)
      end

      it 'returns complete information in correct order' do
        expected_message = 'Turma: 1º Ano A;<br>Aluno: João Silva;<br>Componente curricular: Matemática;<br>'
        expect(builder.build).to eq(expected_message)
      end
    end

    context 'when info contains partial fields' do
      let(:info) do
        {
          'classroom' => '123',
          'discipline' => '789'
        }
      end

      before do
        allow(Classroom).to receive(:find_by).with(api_code: '123').and_return(classroom)
        allow(Discipline).to receive(:find_by).with(api_code: '789').and_return(discipline)
      end

      it 'returns only available information' do
        expected_message = 'Turma: 1º Ano A;<br>Componente curricular: Matemática;<br>'
        expect(builder.build).to eq(expected_message)
      end
    end

    context 'when records are not found' do
      let(:info) do
        {
          'classroom' => '999',
          'student' => '888',
          'discipline' => '777'
        }
      end

      before do
        allow(Classroom).to receive(:find_by).with(api_code: '999').and_return(nil)
        allow(Student).to receive(:find_by).with(api_code: '888').and_return(nil)
        allow(Discipline).to receive(:find_by).with(api_code: '777').and_return(nil)
      end

      it 'returns message with nil values' do
        expected_message = 'Turma: ;<br>Aluno: ;<br>Componente curricular: ;<br>'
        expect(builder.build).to eq(expected_message)
      end
    end
  end

  describe 'private methods' do
    describe '#student' do
      context 'when student exists' do
        before do
          allow(Student).to receive(:find_by).with(api_code: '456').and_return(student)
        end

        it 'returns student name' do
          expect(builder.send(:student, '456')).to eq('João Silva')
        end

        it 'caches the result' do
          expect(Student).to receive(:find_by).once.and_return(student)

          # Primeira chamada
          builder.send(:student, '456')
          # Segunda chamada deve usar cache
          builder.send(:student, '456')
        end
      end

      context 'when student does not exist' do
        before do
          allow(Student).to receive(:find_by).with(api_code: '999').and_return(nil)
        end

        it 'returns nil' do
          expect(builder.send(:student, '999')).to be_nil
        end
      end
    end

    describe '#discipline' do
      context 'when discipline exists' do
        before do
          allow(Discipline).to receive(:find_by).with(api_code: '789').and_return(discipline)
        end

        it 'returns discipline description' do
          expect(builder.send(:discipline, '789')).to eq('Matemática')
        end

        it 'caches the result' do
          expect(Discipline).to receive(:find_by).once.and_return(discipline)

          # Primeira chamada
          builder.send(:discipline, '789')
          # Segunda chamada deve usar cache
          builder.send(:discipline, '789')
        end
      end

      context 'when discipline does not exist' do
        before do
          allow(Discipline).to receive(:find_by).with(api_code: '999').and_return(nil)
        end

        it 'returns nil' do
          expect(builder.send(:discipline, '999')).to be_nil
        end
      end
    end

    describe '#classroom' do
      context 'when classroom exists' do
        before do
          allow(Classroom).to receive(:find_by).with(api_code: '123').and_return(classroom)
        end

        it 'returns classroom description' do
          expect(builder.send(:classroom, '123')).to eq('1º Ano A')
        end

        it 'caches the result' do
          expect(Classroom).to receive(:find_by).once.and_return(classroom)

          # Primeira chamada
          builder.send(:classroom, '123')
          # Segunda chamada deve usar cache
          builder.send(:classroom, '123')
        end
      end

      context 'when classroom does not exist' do
        before do
          allow(Classroom).to receive(:find_by).with(api_code: '999').and_return(nil)
        end

        it 'returns nil' do
          expect(builder.send(:classroom, '999')).to be_nil
        end
      end
    end
  end

  describe 'caching behavior' do
    let(:info) do
      {
        'classroom' => '123',
        'student' => '456',
        'discipline' => '789'
      }
    end

    before do
      allow(Classroom).to receive(:find_by).with(api_code: '123').and_return(classroom)
      allow(Student).to receive(:find_by).with(api_code: '456').and_return(student)
      allow(Discipline).to receive(:find_by).with(api_code: '789').and_return(discipline)
    end

    it 'caches all lookups when building message multiple times' do
      # Expectativas: cada find_by deve ser chamado apenas uma vez
      expect(Classroom).to receive(:find_by).once.and_return(classroom)
      expect(Student).to receive(:find_by).once.and_return(student)
      expect(Discipline).to receive(:find_by).once.and_return(discipline)

      # Primeira construção
      builder.build
      # Segunda construção deve usar cache
      builder.build
      # Terceira construção deve usar cache
      builder.build
    end

    it 'maintains separate caches for different api_codes' do
      # Configuração para diferentes códigos
      classroom2 = double('Classroom', description: '2º Ano B')
      allow(Classroom).to receive(:find_by).with(api_code: '124').and_return(classroom2)

      # Primeira chamada
      expect(builder.send(:classroom, '123')).to eq('1º Ano A')
      # Segunda chamada com código diferente
      expect(builder.send(:classroom, '124')).to eq('2º Ano B')
      # Terceira chamada com primeiro código (deve usar cache)
      expect(builder.send(:classroom, '123')).to eq('1º Ano A')

      # Verifica que ambos estão no cache
      cache = builder.send(:classrooms_cache)
      expect(cache['123']).to eq('1º Ano A')
      expect(cache['124']).to eq('2º Ano B')
    end
  end

  describe 'integration scenarios' do
    context 'when building messages for multiple different infos' do
      it 'handles different combinations correctly' do
        # Configuração dos mocks
        allow(Classroom).to receive(:find_by).with(api_code: '123').and_return(classroom)
        allow(Student).to receive(:find_by).with(api_code: '456').and_return(student)
        allow(Discipline).to receive(:find_by).with(api_code: '789').and_return(discipline)

        # Cenário 1: Apenas turma
        builder1 = described_class.new({ 'classroom' => '123' })
        expect(builder1.build).to eq('Turma: 1º Ano A;<br>')

        # Cenário 2: Turma e aluno
        builder2 = described_class.new({ 'classroom' => '123', 'student' => '456' })
        expect(builder2.build).to eq('Turma: 1º Ano A;<br>Aluno: João Silva;<br>')

        # Cenário 3: Todos os campos
        builder3 = described_class.new({ 'classroom' => '123', 'student' => '456', 'discipline' => '789' })
        expect(builder3.build).to eq('Turma: 1º Ano A;<br>Aluno: João Silva;<br>Componente curricular: Matemática;<br>')
      end
    end

    context 'when handling edge cases' do
      it 'handles empty strings and special characters' do
        # Dados com caracteres especiais
        special_classroom = double('Classroom', description: 'Turma "Especial" & Avançada')
        special_student = double('Student', name: "Maria D'Silva")
        special_discipline = double('Discipline', description: 'Língua Portuguesa (Gramática)')

        allow(Classroom).to receive(:find_by).with(api_code: '100').and_return(special_classroom)
        allow(Student).to receive(:find_by).with(api_code: '200').and_return(special_student)
        allow(Discipline).to receive(:find_by).with(api_code: '300').and_return(special_discipline)

        info = { 'classroom' => '100', 'student' => '200', 'discipline' => '300' }
        builder = described_class.new(info)

        expected = 'Turma: Turma "Especial" & Avançada;<br>Aluno: Maria D\'Silva;<br>Componente curricular: Língua Portuguesa (Gramática);<br>'
        expect(builder.build).to eq(expected)
      end
    end

    context 'when dealing with performance' do
      it 'avoids n+1 queries through caching' do
        # Simula múltiplas chamadas com mesmo código
        allow(Student).to receive(:find_by).with(api_code: '456').and_return(student)

        # Deve fazer apenas uma consulta ao banco
        expect(Student).to receive(:find_by).once

        # Múltiplas chamadas
        5.times { builder.send(:student, '456') }
      end
    end
  end
end

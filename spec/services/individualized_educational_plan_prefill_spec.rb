require 'rails_helper'

RSpec.describe IndividualizedEducationalPlanPrefill, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  describe '.student_data' do
    let(:student) { create(:student, birth_date: Date.new(2015, 3, 10)) }

    before do
      allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
    end

    it 'returns the student birth date' do
      allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))

      expect(described_class.student_data(student)[:birth_date]).to eq('10/03/2015')
    end

    it 'returns the deficiency names as diagnosis' do
      create(:deficiency_student, student: student, deficiency: create(:deficiency, name: 'TEA'))
      allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))

      expect(described_class.student_data(student)[:diagnosis]).to eq('TEA')
    end

    it 'fetches the guardians from the i-Educar API' do
      api = double
      allow(api).to receive(:fetch_by_id).with(student.api_code)
        .and_return('id' => student.api_code, 'nomes_responsaveis' => ['Maria Silva', 'João Silva'])
      allow(IeducarApi::Students).to receive(:new).and_return(api)

      data = described_class.student_data(student)
      expect(data[:guardians]).to eq('Maria Silva, João Silva')
      expect(data[:guardians_unavailable]).to eq(false)
    end

    it 'flags guardians as unavailable (not "no guardians") on a network/API failure, without notifying Honeybadger again' do
      api = double
      allow(api).to receive(:fetch_by_id).and_raise(IeducarApi::Base::GenericError.new('boom'))
      allow(IeducarApi::Students).to receive(:new).and_return(api)
      expect(Honeybadger).not_to receive(:notify)

      data = described_class.student_data(student)
      expect(data[:guardians]).to be_nil
      expect(data[:guardians_unavailable]).to eq(true)
    end

    it 'flags guardians as unavailable when the response is from another student (contract mismatch)' do
      api = double
      allow(api).to receive(:fetch_by_id).and_return('id' => 'outro-codigo', 'nomes_responsaveis' => ['Fulano'])
      allow(IeducarApi::Students).to receive(:new).and_return(api)

      data = described_class.student_data(student)
      expect(data[:guardians]).to be_nil
      expect(data[:guardians_unavailable]).to eq(true)
    end

    it 'does not flag as unavailable when the student simply has no guardians' do
      api = double
      allow(api).to receive(:fetch_by_id).and_return('id' => student.api_code, 'nomes_responsaveis' => [])
      allow(IeducarApi::Students).to receive(:new).and_return(api)

      data = described_class.student_data(student)
      expect(data[:guardians]).to be_nil
      expect(data[:guardians_unavailable]).to eq(false)
    end

    it 'flags guardians as unavailable when the API is not configured (ApiError) instead of losing the form' do
      allow(IeducarApi::Students).to receive(:new).and_raise(IeducarApi::Base::ApiError.new('sem configuração'))

      data = described_class.student_data(student)
      expect(data[:guardians]).to be_nil
      expect(data[:guardians_unavailable]).to eq(true)
    end

    context 'shift (turma do perfil)' do
      before { allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {})) }

      def enroll(target_student, classroom, period: nil)
        classrooms_grade = create(:classrooms_grade, classroom: classroom)
        enrollment = create(:student_enrollment, student: target_student)
        create(:student_enrollment_classroom, student_enrollment: enrollment,
                                              classrooms_grade: classrooms_grade, period: period)
      end

      it 'is nil when no classroom is given' do
        expect(described_class.student_data(student)[:shift]).to be_nil
      end

      it 'returns the classroom shift' do
        classroom = create(:classroom, period: Periods::MATUTINAL)
        enroll(student, classroom)

        expect(described_class.student_data(student, classroom: classroom)[:shift]).to eq('Matutino')
      end

      it 'uses the student period within a full-time classroom as the shift' do
        classroom = create(:classroom, period: Periods::FULL)
        enroll(student, classroom, period: Periods::VESPERTINE)

        expect(described_class.student_data(student, classroom: classroom)[:shift]).to eq('Vespertino')
      end
    end
  end

  describe 'medical reports (laudos do cadastro do aluno no i-Educar)' do
    let(:student) { create(:student) }
    let(:laudo) do
      { 'url' => 'https://s3.amazonaws.com/laudo-assinado', 'size' => 0,
        'original_name' => 'laudo_tea.pdf', 'extension' => 'pdf',
        'created_at' => '2023-04-27T12:36:18.000000Z' }
    end

    before do
      allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
    end

    def stub_api(response)
      api = double
      allow(api).to receive(:fetch_by_id).and_return(response)
      allow(IeducarApi::Students).to receive(:new).and_return(api)
      api
    end

    describe '.medical_reports_data' do
      it 'maps name and sent date, without exposing the signed url (expires in 5 minutes)' do
        stub_api('id' => student.api_code, 'laudos' => [laudo])

        expect(described_class.medical_reports_data(student)).to eq(
          medical_reports: [{ name: 'laudo_tea.pdf', sent_at: '27/04/2023' }],
          medical_reports_unavailable: false
        )
      end

      it 'returns an empty list when the student has no medical reports' do
        stub_api('id' => student.api_code, 'laudos' => [])

        expect(described_class.medical_reports_data(student)).to eq(
          medical_reports: [], medical_reports_unavailable: false
        )
      end

      it 'flags as unavailable (not "no reports") when the i-Educar query fails' do
        api = double
        allow(api).to receive(:fetch_by_id).and_raise(IeducarApi::Base::GenericError.new('boom'))
        allow(IeducarApi::Students).to receive(:new).and_return(api)

        expect(described_class.medical_reports_data(student)).to eq(
          medical_reports: [], medical_reports_unavailable: true
        )
      end
    end

    describe '.medical_report_url' do
      it 'resolves the signed url of the requested report' do
        stub_api('id' => student.api_code, 'laudos' => [laudo])

        expect(described_class.medical_report_url(student, 'laudo_tea.pdf'))
          .to eq('https://s3.amazonaws.com/laudo-assinado')
      end

      it 'returns nil when no report matches the requested name' do
        stub_api('id' => student.api_code, 'laudos' => [laudo])

        expect(described_class.medical_report_url(student, 'outro.pdf')).to be_nil
      end

      it 'does not query the i-Educar API without a name' do
        expect(IeducarApi::Students).not_to receive(:new)

        expect(described_class.medical_report_url(student, '')).to be_nil
      end
    end

    describe '.student_data' do
      it 'includes the medical reports from the SAME i-Educar query used for the guardians' do
        api = double
        expect(api).to receive(:fetch_by_id).once
          .and_return('id' => student.api_code, 'nomes_responsaveis' => ['Maria Silva'],
                      'laudos' => [laudo])
        allow(IeducarApi::Students).to receive(:new).and_return(api)

        data = described_class.student_data(student)

        expect(data[:guardians]).to eq('Maria Silva')
        expect(data[:medical_reports]).to eq([{ name: 'laudo_tea.pdf', sent_at: '27/04/2023' }])
        expect(data[:medical_reports_unavailable]).to eq(false)
      end
    end
  end

  describe '.local_student_data' do
    let(:student) { create(:student, birth_date: Date.new(2015, 3, 10)) }

    it 'returns birth date, diagnosis and shift without hitting the i-Educar API' do
      expect(IeducarApi::Students).not_to receive(:new)

      data = described_class.local_student_data(student)

      expect(data).to eq(birth_date: '10/03/2015', diagnosis: nil, shift: nil)
    end

    it 'does not include guardians in the returned hash' do
      expect(described_class.local_student_data(student).key?(:guardians)).to eq(false)
    end
  end
end

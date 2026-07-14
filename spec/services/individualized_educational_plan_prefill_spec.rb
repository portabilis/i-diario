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
                                         .and_return('nomes_responsaveis' => ['Maria Silva', 'João Silva'])
      allow(IeducarApi::Students).to receive(:new).and_return(api)

      expect(described_class.student_data(student)[:guardians]).to eq('Maria Silva, João Silva')
    end

    it 'returns nil guardians and notifies Honeybadger when the API fails' do
      allow(IeducarApi::Students).to receive(:new).and_raise(StandardError.new('boom'))
      expect(Honeybadger).to receive(:notify)

      expect(described_class.student_data(student)[:guardians]).to be_nil
    end

    context 'classrooms' do
      let(:unity) { create(:unity) }
      let(:year) { Date.current.year }

      before { allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {})) }

      def enroll(target_student, classroom, period: nil)
        classrooms_grade = create(:classrooms_grade, classroom: classroom)
        enrollment = create(:student_enrollment, student: target_student)
        create(:student_enrollment_classroom, student_enrollment: enrollment,
                                              classrooms_grade: classrooms_grade, period: period)
      end

      it 'is empty when no unity is given' do
        expect(described_class.student_data(student)[:classrooms]).to eq([])
      end

      it 'returns the classrooms of the student in the unity/year with the classroom shift' do
        classroom = create(:classroom, unity: unity, year: year, period: Periods::MATUTINAL)
        enroll(student, classroom)

        result = described_class.student_data(student, unity: unity, year: year)[:classrooms]

        expect(result).to contain_exactly(
          hash_including(id: classroom.id, name: classroom.description, shift: 'Matutino', teacher: nil)
        )
      end

      it 'uses the student period within a full-time classroom as the shift' do
        classroom = create(:classroom, unity: unity, year: year, period: Periods::FULL)
        enroll(student, classroom, period: Periods::VESPERTINE)

        result = described_class.student_data(student, unity: unity, year: year)[:classrooms]

        expect(result.first[:shift]).to eq('Vespertino')
      end
    end
  end
end

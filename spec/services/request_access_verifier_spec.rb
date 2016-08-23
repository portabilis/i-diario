require 'spec_helper_lite'

require 'app/services/request_access_verifier'

RSpec.describe RequestAccessVerifier, type: :service do
  let(:student) { double :student, api_code: "1" }
  let(:student_api_code) { "1" }
  let(:unity) { double :unity, api_code: "1" }
  let(:unity_api_code) { "1" }
  let(:unity_equipment) { double :unity_equipment, code: "1", biometric_type: biometric_type}
  let(:unity_equipment_code) { "1" }
  let(:biometric_string) { "8d18912h81921819" }
  let(:student_biometric) { double :student_biometric, biometric_type: 1, biometric: biometric_string }
  let(:biometric_type) { 1 }
  let(:student_present_unity) { true }
  let(:student_unity_checker) { double :student_unity_checker }
  let(:way) { 3 }
  let(:time) { "2016-07-06T15:47:53" }
  let(:request_type) { 3 }

  subject do
    RequestAccessVerifier.new(student_api_code, unity_api_code, unity_equipment_code, way, time, request_type)
  end

  before do
    stub_student
    stub_unity
    stub_unity_equipment
    stub_student_biometric
    stub_student_unity_checker
  end

  describe '#process!' do
    context 'when way is invalid' do
      let(:way) { 4 }
      it "should return false" do
        expect(subject.process!).to be(false)
      end
    end

    context 'when time is invalid' do
      let(:time) { "asd" }
      it "should return false" do
        expect(subject.process!).to be(false)
      end
    end

    context 'when request_type is invalid' do
      let(:request_type) { 0 }
      it "should return false" do
        expect(subject.process!).to be(false)
      end
    end

    context 'when student not exists' do
      let(:student_api_code) { "2" }
      it "should return false" do
        expect(subject.process!).to be(false)
      end
    end

    context 'when unity not exists' do
      let(:unity_api_code) { "2" }
      it "should return false" do
        expect(subject.process!).to be(false)
      end
    end

    context 'when unity equipment not exists' do
      let(:unity_api_code) { "2" }
      it "should return false" do
        expect(subject.process!).to be(false)
      end
    end

    context 'when unity equipment not exists' do
      let(:unity_equipment_code) { "2" }
      it "should return false" do
        expect(subject.process!).to be(false)

      end
    end

    context 'when student biometric not exists' do
      let(:biometric_type) { 2 }
      it "should return false" do
        expect(subject.process!).to be(false)
      end
    end

    context 'when student is not present in unity' do
      let(:student_present_unity) { false }
      it "should return false" do
        expect(subject.process!).to be(false)
      end
    end

    context 'when all paramters are ok' do
      it "should return true" do
        expect(subject.process!).to be(true)
      end
    end
  end

  describe '#response_msg' do
    context 'when way is invalid' do
      let(:way) { 4 }
      it "should return 'Sentido inválido'" do
        subject.process!
        expect(subject.response_msg).to eq('Sentido inválido')
      end
    end

    context 'when time is invalid' do
      let(:time) { "asd" }
      it "should return 'Data e hora inválida'" do
        subject.process!
        expect(subject.response_msg).to eq('Data e hora inválida')
      end
    end

    context 'when request_type is invalid' do
      let(:request_type) { 0 }
      it "should return 'Tipo de consulta inválida'" do
        subject.process!
        expect(subject.response_msg).to eq('Tipo de consulta inválida')
      end
    end

    context 'when way is invalid' do
      let(:way) { 4 }
      it "should return 'Sentido inválido'" do
        subject.process!
        expect(subject.response_msg).to eq('Sentido inválido')
      end
    end

    context 'when student not exists' do
      let(:student_api_code) { "2" }
      it "should return 'Aluno inválido'" do
        subject.process!
        expect(subject.response_msg).to eq('Aluno inválido')
      end
    end

    context 'when unity not exists' do
      let(:unity_api_code) { "2" }
      it "should return 'Escola inválida'" do
        subject.process!
        expect(subject.response_msg).to eq('Escola inválida')
      end
    end

    context 'when unity equipment not exists' do
      let(:unity_api_code) { "2" }
      it "should return 'Escola inválida'" do
        subject.process!
        expect(subject.response_msg).to eq('Escola inválida')
      end
    end

    context 'when unity equipment not exists' do
      let(:unity_equipment_code) { "2" }
      it "should return 'Equipamento inválido'" do
        subject.process!
        expect(subject.response_msg).to eq('Equipamento inválido')
      end
    end

    context 'when student biometric not exists' do
      let(:biometric_type) { 2 }
      it "should return 'Biometria não cadastrada'" do
        subject.process!
        expect(subject.response_msg).to eq('Biometria não cadastrada')
      end
    end

    context 'when student is not present in unity' do
      let(:student_present_unity) { false }
      it "should return 'Acesso negado'" do
        subject.process!
        expect(subject.response_msg).to eq('Acesso negado')
      end
    end

    context 'when all paramters are ok' do
      it "should return 'OK'" do
        subject.process!
        expect(subject.response_msg).to eq('OK')
      end
    end
  end

  describe '#biometric' do
    context 'when all paramters are ok' do
      it "should return biometric_string" do
        subject.process!
        expect(subject.biometric).to eq(biometric_string)
      end
    end
  end

  def stub_student
    stub_const('Student', Class.new)
    allow(Student).to(
      receive(:find_by).with(
          api_code: student_api_code
        )
        .and_return(student.api_code == student_api_code ? student : nil)
    )
    allow(student).to receive(:id).and_return(1)
  end

  def stub_unity
    stub_const('Unity', Class.new)
    allow(Unity).to(
      receive(:find_by).with(
          api_code: unity_api_code
        )
        .and_return(unity.api_code == unity_api_code ? unity : nil)
    )
    allow(unity).to receive(:id).and_return(1)
  end

  def stub_unity_equipment
    stub_const('UnityEquipment', Class.new)
    allow(UnityEquipment).to(
      receive(:find_by).with(
          code: unity_equipment_code,
          unity_id: unity.id
        )
        .and_return(unity_equipment.code == unity_equipment_code ? unity_equipment : nil)
    )
  end

  def stub_student_biometric
    stub_const('StudentBiometric', Class.new)
    allow(StudentBiometric).to(
      receive(:find_by).with(
          biometric_type: biometric_type,
          student_id: student.id
        )
        .and_return(student_biometric.biometric_type == biometric_type ? student_biometric : nil)
    )
  end

  def stub_student_unity_checker
    stub_const('StudentUnityChecker', Class.new)
    allow(StudentUnityChecker).to(
      receive(:new).with(student, unity).and_return(student_unity_checker)
    )
    allow(student_unity_checker).to(
      receive(:present?).and_return(student_present_unity)
    )
  end
end
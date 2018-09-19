require 'spec_helper_lite'

require 'app/services/student_unity_checker'

RSpec.describe StudentUnityChecker, type: :service do
  let(:student) { double :student, api_code: "1" }
  let(:unity) { double :unity, api_code: "1" }

  subject do
    StudentUnityChecker.new(student, unity)
  end

  before do
    stub_subject
  end

  describe '#present?' do
    context 'when student is present in unity' do
      it "should return true" do
        expect(subject.present?).to be(true)
      end
    end

    context 'when student is not present in unity' do
      let(:unity) { double :unity, api_code: "2" }
      it "should return false" do
        expect(subject.present?).to be(false)
      end
    end
  end

  def stub_subject
    allow(subject).to receive(:get_student_registrations).with(student.api_code){
      [
        {
          "codigo_situacao" => "3",
          "escola_id" => "1",
          "ano" => Date.current.year.to_s
        }
      ]
    }
  end
end
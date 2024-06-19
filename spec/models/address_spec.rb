require 'rails_helper'

RSpec.describe Address, :type => :model do
  describe "Validations" do
    it { should allow_value("32672-124").for(:zip_code) }
    it { should_not allow_value("32672124").for(:zip_code) }
    it { should_not allow_value("3267-124").for(:zip_code) }
  end

  describe 'methods' do
    subject { create(:address) }

    describe '#country' do
      it "returns string 'Brasil'" do
        expect(subject.country).to eq('Brasil')
      end
    end

    describe "#to_s" do
      context 'with complete address' do
        it 'returns formatted address' do
          subject.assign_attributes(street: 'Rua 1', number: '100',
                                    neighborhood: 'Bairro',
                                    zip_code: '32672-124',
                                    city: 'Rio Branco', state: 'AC' )

          expect(subject.to_s).to eq(
            'Rua 1, 100, Bairro, CEP: 32672-124, Rio Branco, AC'
          )
        end
      end
    end
  end
end

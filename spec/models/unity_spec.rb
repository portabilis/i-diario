# encoding: utf-8
require 'rails_helper'

RSpec.describe Unity, :type => :model do
  context "associations" do
    it { should belong_to :author }
    it { should have_one :address }
    it { should have_many :unity_equipments }
  end

  context "Validations" do
    it { should allow_value('').for(:phone) }
    it { should allow_value('(33) 33445566').for(:phone) }
    it { should allow_value('(33) 334445556').for(:phone) }
    it { should_not allow_value('(33) 3344-5565').for(:phone) }
    it { should_not allow_value('(33) 3344-556').for(:phone) }
    it { should_not allow_value('(33) 3344556').for(:phone) }

    it { should allow_value('admin@example.com').for(:email) }
    it { should_not allow_value('admin@examplecom', 'adminexample.com').for(:email).
         with_message("use apenas letras (a-z), números e pontos.") }

    it { should validate_presence_of :author }
    it { should validate_presence_of :name }
    it { should validate_presence_of :unit_type }

    describe 'name uniqueness' do
      let(:author) { create(:user) }

      context 'when there is no discarded unity with the same name' do
        it 'should not allow duplicate names' do
          create(:unity, name: 'Escola Teste', author: author)
          duplicate_unity = build(:unity, name: 'Escola Teste', author: author)

          expect(duplicate_unity).to_not be_valid
          expect(duplicate_unity.errors[:name]).to include('já está em uso')
        end
      end

      context 'when there is a discarded unity with the same name' do
        it 'should allow creating a new unity with the same name' do
          discarded_unity = create(:unity, name: 'Escola Descartada', author: author)
          discarded_unity.discard

          new_unity = build(:unity, name: 'Escola Descartada', author: author)

          expect(new_unity).to be_valid
        end
      end
    end
  end
end

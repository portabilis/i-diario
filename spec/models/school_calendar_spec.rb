# encoding: utf-8
require 'rails_helper'

RSpec.describe SchoolCalendar, :type => :model do
  describe "associations" do
    it { should have_many :steps }
  end

  describe "validations" do
    it { should validate_presence_of :year }
    it { should validate_presence_of :number_of_classes }

    it "validates at least one assigned step" do
      subject.steps = []

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:steps]).to include
        "É necessário adicionar pelo menos uma etapa"
    end
  end
end

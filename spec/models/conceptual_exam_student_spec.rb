# encoding: utf-8
require 'rails_helper'

RSpec.describe ConceptualExamStudent, type: :model do
  describe "associations" do
    it { should belong_to :conceptual_exam }
    it { should belong_to :student }
  end

  describe "validations" do
    it { should validate_presence_of :student }
    it { should validate_presence_of :conceptual_exam }
  end
end

# encoding: utf-8
require 'rails_helper'

RSpec.describe DescriptiveExamStudent, type: :model do
  describe "associations" do
    it { should belong_to :descriptive_exam }
    it { should belong_to :student }
  end

  describe "validations" do
    it { should validate_presence_of :student }
    it { should validate_presence_of :descriptive_exam }
  end
end

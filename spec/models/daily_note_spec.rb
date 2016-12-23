# encoding: utf-8
require 'rails_helper'

RSpec.describe DailyNote, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to(:avaliation) }
    it { expect(subject).to have_many(:students).dependent(:destroy) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:avaliation) }
  end
end

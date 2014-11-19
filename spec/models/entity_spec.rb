require 'rails_helper'

RSpec.describe Entity, :type => :model do
  context "Associations" do
    it { should have_one :notification }
  end

  context "Validations" do
    it { should validate_presence_of :name }
    it { should validate_presence_of :domain }
    it { should validate_presence_of :config }
  end
end

require 'rails_helper'

RSpec.describe UserLogin, :type => :model do
  context "Associations" do
    it { should belong_to :user }
  end

  context "Validations" do
    it { should validate_presence_of :user }
    it { should validate_presence_of :sign_in_ip }
  end
end

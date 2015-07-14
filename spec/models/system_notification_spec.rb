require 'rails_helper'

RSpec.describe SystemNotification, :type => :model do
  context "Validations" do
    it { should validate_presence_of :source }
    it { should validate_presence_of :title }
    it { should validate_presence_of :description }
  end
end

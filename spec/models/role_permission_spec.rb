require 'rails_helper'

RSpec.describe RolePermission, :type => :model do
  context "Associations" do
    it { should belong_to :role }
  end
end

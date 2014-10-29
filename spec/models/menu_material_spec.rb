require 'rails_helper'

RSpec.describe Menu***REMOVED***, :type => :model do
  describe "associations" do
    it { should belong_to :***REMOVED*** }
    it { should belong_to :material }
    it { should have_one(:measuring_unit).through :material }
  end

  describe "validations" do
    it { should validate_presence_of :material_id }
    it { should validate_numericality_of :quantity }
  end
end

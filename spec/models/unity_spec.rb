require 'rails_helper'

RSpec.describe Unity, :type => :model do
  context "Validations" do
    it { should allow_value('').for(:phone) }
    it { should allow_value('(33) 3344-5566').for(:phone) }
    it { should_not allow_value('(33) 33445565').for(:phone) }
    it { should_not allow_value('(33) 3344-556').for(:phone) }

    it { should allow_value('admin@example.com').for(:email) }
    it { should_not allow_value('admin@examplecom').for(:email) }
    it { should_not allow_value('adminexample.com').for(:email) }
  end
end

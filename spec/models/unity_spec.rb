# encoding: utf-8
require 'rails_helper'

RSpec.describe Unity, :type => :model do
  context "associations" do
    it { should belong_to :author }
    it { should have_one :address }
    it { should have_many :origin_***REMOVED*** }
    it { should have_many :destination_***REMOVED*** }
  end

  context "Validations" do
    it { should allow_value('').for(:phone) }
    it { should allow_value('(33) 3344-5566').for(:phone) }
    it { should allow_value('(33) 33444-5556').for(:phone) }
    it { should_not allow_value('(33) 33445565').for(:phone) }
    it { should_not allow_value('(33) 3344-556').for(:phone) }

    it { should allow_value('admin@example.com').for(:email) }
    it { should_not allow_value('admin@examplecom', 'adminexample.com').for(:email).
         with_message("use apenas letras (a-z), números e pontos.") }

    it { should validate_presence_of :author }
    it { should validate_presence_of :name }
    it { should validate_presence_of :unit_type }
  end
end

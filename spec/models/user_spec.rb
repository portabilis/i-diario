require 'rails_helper'

RSpec.describe User, :type => :model do
  it 'have false as default value for authorize_email_and_sms' do
    expect(subject.authorize_email_and_sms).to eq false
  end

  it { should validate_presence_of(:email) }

  it { should allow_value('').for(:phone) }
  it { should allow_value('(33) 3344-5566').for(:phone) }
  it { should_not allow_value('(33) 33445565').for(:phone) }
  it { should_not allow_value('(33) 3344-556').for(:phone) }

  it { should allow_value('').for(:cpf) }
  it { should allow_value('531.880.033-58').for(:cpf) }
  it { should_not allow_value('531.880.033-5').for(:cpf) }
  it { should_not allow_value('531.880.033-587').for(:cpf) }

  it { should allow_value('admin@example.com').for(:email) }
  it { should_not allow_value('admin@examplecom').for(:email) }
  it { should_not allow_value('adminexample.com').for(:email) }
end

require 'rails_helper'

RSpec.describe Student, :type => :model do
  context "Validations" do
    it { should validate_presence_of :name }
    it { should_not validate_presence_of :api_code }

    context "as a api record" do
      before do
        subject.api = true
      end

      it { should validate_presence_of :api_code }
    end
  end
end

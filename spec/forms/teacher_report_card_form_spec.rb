require 'rails_helper'

RSpec.describe TeacherReportCardForm, type: :model do
  describe "validations" do

    it { expect(subject).to validate_presence_of(:unity_id) }
    it { expect(subject).to validate_presence_of(:classroom_id) }
    it { expect(subject).to validate_presence_of(:discipline_id) }

  end
end

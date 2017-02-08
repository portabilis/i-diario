require 'rails_helper'

RSpec.describe SchoolCalendarClassroom, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to(:school_calendar) }
    it { expect(subject).to belong_to(:classroom) }
  end
end

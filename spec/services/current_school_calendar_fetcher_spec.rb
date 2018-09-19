require 'spec_helper_lite'
require 'app/services/current_school_calendar_fetcher'

RSpec.describe CurrentSchoolCalendarFetcher, type: :service do
  let(:unity) { double :unity }
  let(:classroom) { double :classroom }
  let(:classroom_calendar) { double :classroom_calendar }
  let(:school_calendar) { double :school_calendar }
  let(:school_calendar_query) { double :school_calendar_query }
  let(:school_calendar_classroom_query) { double :school_calendar_classroom_query }

  before do
    stub_classroom
    stub_school_calendar_query
    stub_school_calendar_classroom_query
  end

  subject do
    described_class.new(unity, classroom)
  end

  describe "#fetch" do
    context "when has no classroom calendar" do
      let(:classroom_calendar) { nil }

      it "should work" do
        expect(subject.fetch).to be(school_calendar)
      end
    end

    context "when has classroom calendar" do
      it "should work" do
        expect(subject.fetch).to be(classroom_calendar)
      end
    end
  end

  private

  def stub_classroom
    allow(classroom).to receive(:calendar).and_return(classroom_calendar)
  end

  def stub_school_calendar_query
    stub_const('SchoolCalendarQuery', Class.new)
    allow(SchoolCalendarQuery).to(
      receive(:new).with(unity, nil).and_return(school_calendar_query)
    )
    allow(school_calendar_query).to receive(:school_calendar).and_return(school_calendar)
  end

  def stub_school_calendar_classroom_query
    stub_const('SchoolCalendarClassroomQuery', Class.new)
    allow(SchoolCalendarClassroomQuery).to(
      receive(:new).with(unity, classroom).and_return(school_calendar_classroom_query)
    )
    allow(school_calendar_classroom_query).to receive(:school_calendar).and_return(classroom_calendar)
  end
end

require 'spec_helper_lite'
require 'app/services/current_school_year_fetcher'

RSpec.describe CurrentSchoolYearFetcher, type: :service do

  let(:unity) { double(:unity) }
  let(:current_school_calendar_fetcher) { double(:current_school_calendar_fetcher) }
  let(:school_calendar) { double(:school_calendar) }
  let(:year) { double(:year) }

  before do
    stub_current_school_calendar_fetcher
  end

  subject do
    described_class.new(unity)
  end

  describe "#fetch" do
    context "when was given a unity" do
      let(:year) { 2017 }
      it "should return a school calendar year" do
        expect(subject.fetch).to eq(2017)
      end
    end

    context "when has no calendar" do
      let(:school_calendar) { nil }
      it "should return nil" do
        expect(subject.fetch).to eq(nil)
      end
    end
  end

  private

  def stub_current_school_calendar_fetcher
    stub_const('CurrentSchoolCalendarFetcher', Class.new)
    allow(CurrentSchoolCalendarFetcher).to(
      receive(:new).with(unity, nil).and_return(current_school_calendar_fetcher)
    )
    allow(current_school_calendar_fetcher).to receive(:fetch).and_return(school_calendar)
    allow(school_calendar).to receive(:year).and_return(year)
  end
end

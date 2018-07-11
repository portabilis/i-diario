require 'spec_helper_lite'
require 'date'

require 'app/services/weeks_in_period_counter'

RSpec.describe WeeksInPeriodCounter, type: :service do
  describe '.count' do
    it "should count weeks with weekday in period" do
      expect(described_class::count(Date.new(2018,4,13), Date.new(2018,4,13))).to be(1)
      expect(described_class::count(Date.new(2018,4,13), Date.new(2018,4,15))).to be(1)
      expect(described_class::count(Date.new(2018,4,14), Date.new(2018,4,16))).to be(1)
      expect(described_class::count(Date.new(2018,4,13), Date.new(2018,4,20))).to be(2)
      expect(described_class::count(Date.new(2018,4,9), Date.new(2018,4,23))).to be(3)
      expect(described_class::count(Date.new(2018,4,9), Date.new(2018,4,27))).to be(3)
    end
  end
end

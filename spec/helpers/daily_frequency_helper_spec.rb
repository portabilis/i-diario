require 'rails_helper'

RSpec.describe DailyFrequencyHelper, type: :helper do
  describe "#params_for_print_month" do
    let(:discipline) { create(:discipline) }
    let(:school_calendar) { create(:school_calendar) }
    let(:teacher) { create(:teacher, :with_teacher_discipline_classroom, discipline: discipline) }

    let(:daily_frequencies) {
      create_list(
        :daily_frequency,
        1,
        :with_teacher_discipline_classroom,
        teacher: teacher,
        classroom: teacher.classrooms.first,
        discipline: discipline,
        frequency_date: '2022-04-01'
      )
    }

    context "#when params are correct" do
      it "returns hash with correct params" do
        helper.instance_variable_set(:@number_of_classes, 2)
        allow(helper).to receive(:current_teacher).and_return(teacher)
        expect(helper.params_for_print_month(daily_frequencies)).to be_empty
      end
    end

  end
end

require 'rails_helper'

RSpec.describe LessonBoardsFetcher, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:current_year) { Date.current.year }

  let(:unity) { create(:unity) }
  let(:unity_without_school_calendar) { create(:unity) }

  let!(:school_calendar) { create(:school_calendar, unity: unity, year: current_year) }

  let(:classroom) { create(:classroom, unity: unity, year: current_year) }
  let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }
  let!(:lessons_board) { create(:lessons_board, classrooms_grade: classrooms_grade) }

  let(:classroom_of_other_unity) do
    create(:classroom, unity: unity_without_school_calendar, year: current_year)
  end
  let!(:lessons_board_of_other_unity) do
    create(:lessons_board, classrooms_grade: create(:classrooms_grade, classroom: classroom_of_other_unity))
  end

  context 'when the user is an administrator' do
    let(:user) { create(:user, :with_user_role_administrator, current_school_year: current_year) }

    subject(:fetcher) { described_class.new(user) }

    it 'returns unities with school calendar on the school year of the profile' do
      expect(fetcher.unities.to_a).to contain_exactly(unity)
    end

    it 'returns only lessons boards of those unities' do
      expect(fetcher.lesson_boards.to_a).to contain_exactly(lessons_board)
    end
  end

  context 'when the user is an employee' do
    let(:employee_role) { create(:role, access_level: AccessLevel::EMPLOYEE) }
    let(:user) { create(:user) }
    let!(:user_role) { create(:user_role, user: user, role: employee_role, unity: unity) }

    subject(:fetcher) { described_class.new(user) }

    before do
      user.current_user_role = user_role
      user.save!
    end

    it 'returns the unities linked to the employee roles of the user' do
      expect(fetcher.unities.to_a).to contain_exactly(unity)
    end

    it 'returns only lessons boards of those unities' do
      expect(fetcher.lesson_boards.to_a).to contain_exactly(lessons_board)
    end

    # A implementação anterior percorria todos os quadros para descobrir as unidades (N+1)
    it 'does not run more queries when there are more lessons boards' do
      queries_with_one_lessons_board = count_queries { described_class.new(user).unities.to_a }

      create_list(:lessons_board, 5, classrooms_grade: create(:classrooms_grade, classroom: classroom))

      expect(count_queries { described_class.new(user).unities.to_a }).to eq(queries_with_one_lessons_board)
    end
  end

  context 'when the user has no role' do
    let(:user) { create(:user) }

    subject(:fetcher) { described_class.new(user) }

    it 'returns no unity' do
      expect(fetcher.unities.to_a).to eq([])
    end

    it 'returns no lessons board' do
      expect(fetcher.lesson_boards.to_a).to eq([])
    end
  end
end

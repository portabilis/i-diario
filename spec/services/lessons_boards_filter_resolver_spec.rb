require 'rails_helper'

RSpec.describe LessonsBoardsFilterResolver, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:current_year) { Date.current.year }
  let(:previous_year) { current_year - 1 }

  let(:unity) { create(:unity) }
  let(:other_unity) { create(:unity) }
  let(:unity_out_of_reach) { create(:unity) }

  let(:grade) { create(:grade) }
  let(:other_grade) { create(:grade) }

  let(:classroom) { create(:classroom, unity: unity, year: current_year) }
  let(:other_classroom) { create(:classroom, unity: other_unity, year: current_year) }
  let(:previous_year_classroom) { create(:classroom, unity: unity, year: previous_year) }

  let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom, grade: grade) }
  let(:other_classrooms_grade) { create(:classrooms_grade, classroom: other_classroom, grade: other_grade) }
  let(:previous_year_classrooms_grade) do
    create(:classrooms_grade, classroom: previous_year_classroom, grade: grade)
  end

  let!(:lessons_board) { create(:lessons_board, classrooms_grade: classrooms_grade) }
  let!(:other_lessons_board) { create(:lessons_board, classrooms_grade: other_classrooms_grade) }
  let!(:previous_year_lessons_board) do
    create(:lessons_board, classrooms_grade: previous_year_classrooms_grade)
  end

  let(:visible_unities) { Unity.where(id: [unity.id, other_unity.id]) }
  let(:fetcher) { double(unities: visible_unities, lesson_boards: LessonsBoard.all) }

  def resolve(search, default_year: current_year)
    described_class.new(search, fetcher: fetcher, default_year: default_year).resolve
  end

  def search_params(attributes)
    ActionController::Parameters.new(attributes)
  end

  describe 'the year' do
    it 'uses the school year of the profile when there is no search' do
      filters = resolve(nil)

      expect(filters.year).to eq(current_year.to_s)
      expect(filters.to_filter_params[:by_year]).to eq(current_year.to_s)
    end

    it 'applies no year filter when the field is cleared' do
      filters = resolve(search_params(by_year: ''))

      expect(filters.to_filter_params[:by_year]).to eq('')
    end

    # Mesmo comportamento da tela de calendário letivo: ano errado filtra e não traz nada
    it 'keeps an incomplete year on the form and filters by it' do
      filters = resolve(search_params(by_year: '20'))

      expect(filters.to_form_params[:by_year]).to eq('20')
      expect(filters.to_filter_params[:by_year]).to eq('20')
    end

    it 'sends a number to the filter when the year is not numeric' do
      filters = resolve(search_params(by_year: 'abc'))

      expect(filters.to_form_params[:by_year]).to eq('abc')
      expect(filters.to_filter_params[:by_year]).to eq('0')
    end
  end

  describe 'the unity' do
    it 'keeps a unity the user has access to' do
      filters = resolve(search_params(by_year: current_year.to_s, by_unity: unity.id.to_s))

      expect(filters.unity_id).to eq(unity.id.to_s)
      expect(filters.unity_id_out_of_reach).to be_nil
    end

    it 'discards a unity outside of the access of the user and reports it' do
      filters = resolve(search_params(by_unity: unity_out_of_reach.id.to_s))

      expect(filters.unity_id).to eq('')
      expect(filters.unity_id_out_of_reach).to eq(unity_out_of_reach.id.to_s)
    end

    it 'keeps the selected unity on the options even without lessons boards on the year' do
      filters = resolve(search_params(by_year: '1999', by_unity: unity.id.to_s))

      expect(filters.unity_options.map(&:id)).to contain_exactly(unity.id)
    end

    it 'offers only unities with lessons boards on the year' do
      filters = resolve(search_params(by_year: previous_year.to_s))

      expect(filters.unity_options.map(&:id)).to contain_exactly(unity.id)
    end

    it 'treats the empty value of select2 as no filter' do
      filters = resolve(search_params(by_unity: Select2Input::EMPTY_ELEMENT_ID))

      expect(filters.unity_id).to eq('')
      expect(filters.unity_id_out_of_reach).to be_nil
    end
  end

  describe 'the cascade' do
    it 'narrows the grades to the selected unity' do
      filters = resolve(search_params(by_year: current_year.to_s, by_unity: unity.id.to_s))

      expect(filters.grade_options.map(&:id)).to contain_exactly(grade.id)
    end

    it 'narrows the classrooms to the selected grade' do
      filters = resolve(
        search_params(by_year: current_year.to_s, by_unity: unity.id.to_s, by_grade: grade.id.to_s)
      )

      expect(filters.classroom_options.map(&:id)).to contain_exactly(classroom.id)
    end

    it 'discards a grade that does not belong to the selected unity' do
      filters = resolve(
        search_params(by_year: current_year.to_s, by_unity: unity.id.to_s, by_grade: other_grade.id.to_s)
      )

      expect(filters.grade_id).to eq('')
    end

    it 'discards a classroom that does not belong to the selected unity' do
      filters = resolve(
        search_params(
          by_year: current_year.to_s, by_unity: unity.id.to_s, by_classroom: other_classroom.id.to_s
        )
      )

      expect(filters.classroom_id).to eq('')
    end

    it 'keeps a valid grade and classroom' do
      filters = resolve(
        search_params(
          by_year: current_year.to_s,
          by_unity: unity.id.to_s,
          by_grade: grade.id.to_s,
          by_classroom: classroom.id.to_s
        )
      )

      expect(filters.grade_id).to eq(grade.id.to_s)
      expect(filters.classroom_id).to eq(classroom.id.to_s)
    end
  end

  describe 'the classroom label' do
    it 'uses the description when a year is filtered' do
      filters = resolve(search_params(by_year: current_year.to_s, by_unity: unity.id.to_s))

      expect(filters.classroom_options.map(&:name)).to contain_exactly(classroom.description)
    end

    # Sem filtro de ano a lista mistura anos e turmas homônimas ficariam indistinguíveis
    it 'appends the year when no year is filtered' do
      filters = resolve(search_params(by_year: '', by_unity: unity.id.to_s))

      expect(filters.classroom_options.map(&:name)).to contain_exactly(
        "#{classroom.description} - #{classroom.year}",
        "#{previous_year_classroom.description} - #{previous_year_classroom.year}"
      )
    end
  end
end

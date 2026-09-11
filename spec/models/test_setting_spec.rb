require 'rails_helper'

RSpec.describe TestSetting, type: :model do
  subject { FactoryGirl.build(:test_setting) }
  let(:school_term_type_step) { create(:school_term_type_step) }

  describe 'attributes' do
    it { expect(subject).to respond_to(:exam_setting_type) }
    it { expect(subject).to respond_to(:school_term_type_step) }
    it { expect(subject).to respond_to(:year) }
    it { expect(subject).to respond_to(:maximum_score) }
    it { expect(subject).to respond_to(:number_of_decimal_places) }
  end

  describe 'associations' do
    it { expect(subject).to have_many(:tests) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:exam_setting_type) }
    it { expect(subject).to validate_presence_of(:year) }

    # FIXME: Not working, probably a bug on shoulda-matchers. Need to be reported.
    # it { expect(subject).to validate_numericality_of(:maximum_score).is_greater_than_or_equal_to(1)
    #                                                                 .is_less_than_or_equal_to(1000)
    #                                                                 .only_integer }


    # FIXME: Not working, probably a bug on shoulda-matchers. Need to be reported.
    # it { expect(subject).to validate_numericality_of(:number_of_decimal_places).is_greater_than_or_equal_to(0)
    #                                                                            .is_less_than_or_equal_to(3)
    #                                                                            .only_integer }

    context 'when #exam_setting_type equals to general' do
      before do
        subject.exam_setting_type = ExamSettingTypes::GENERAL
        subject.school_term_type_step = nil
      end

      it 'should not validate presence of school term' do
        expect(subject.valid?).to be(true)
        expect(subject.errors[:school_term_type_step]).to be_empty
      end

      it 'should validate uniqueness of year' do
        another_test_setting = FactoryGirl.create(:test_setting, exam_setting_type: subject.exam_setting_type,
                                                                 year: subject.year,
                                                                 school_term_type_step: subject.school_term_type_step)

        expect(subject).to_not be_valid
        expect(subject.errors[:year]).to include('já está em uso')
      end
    end

    context 'when #exam_setting_type equals to by_school_term' do
      before { subject.exam_setting_type = ExamSettingTypes::BY_SCHOOL_TERM }

      it 'should validate presence of school term' do
        subject.school_term_type_step = nil

        expect(subject.valid?).to be(false)
        expect(subject.errors[:school_term_type_step]).to include('não pode ficar em branco')
      end

      it 'should validate uniqueness of year' do
        another_test_setting = FactoryGirl.create(:test_setting, exam_setting_type: ExamSettingTypes::GENERAL,
                                                                 year: subject.year)

        expect(subject).to_not be_valid
        expect(subject.errors[:year]).to include('já está em uso')
      end

      it 'should validate uniqueness of year/school_term_type_step' do
        subject.school_term_type_step = school_term_type_step

        another_test_setting = FactoryGirl.create(:test_setting, exam_setting_type: subject.exam_setting_type,
                                                                 year: subject.year,
                                                                 school_term_type_step: subject.school_term_type_step)

        expect(subject).to_not be_valid
        expect(subject.errors[:school_term_type_step]).to include('já está em uso')
      end
    end

    context 'when #exam_setting_type equals to general_by_school' do
      let(:course) { create(:course, description: 'Ensino Fundamental') }
      let(:shared_unity) { create(:unity, name: 'Escola Centro') }
      let(:shared_grade) { create(:grade, description: '1º ano', course: course) }
      let(:other_unity) { create(:unity, name: 'Escola Norte') }
      let(:other_grade) { create(:grade, description: '2º ano', course: course) }

      let!(:existing_test_setting) do
        create(:test_setting, :general_by_school,
               year: 2026,
               unities: [shared_unity.id],
               grades: [shared_grade.id])
      end

      it 'does not allow another setting covering the same unity and grade' do
        test_setting = build(:test_setting, :general_by_school,
                             year: 2026,
                             unities: [shared_unity.id],
                             grades: [shared_grade.id])

        expect(test_setting).to_not be_valid
        expect(test_setting.errors[:grades]).to eq(
          ['A série 1º ano - Ensino Fundamental já está em outra configuração de 2026 para a escola Escola Centro']
        )
      end

      it 'does not allow another setting whose unities only partially overlap' do
        test_setting = build(:test_setting, :general_by_school,
                             year: 2026,
                             unities: [shared_unity.id, other_unity.id],
                             grades: [shared_grade.id])

        expect(test_setting).to_not be_valid
        expect(test_setting.errors[:grades]).to eq(
          ['A série 1º ano - Ensino Fundamental já está em outra configuração de 2026 para a escola Escola Centro']
        )
        expect(test_setting.errors[:unities]).to be_empty
      end

      it 'names every grade and unity in common when several settings overlap' do
        create(:test_setting, :general_by_school, year: 2026, unities: [other_unity.id], grades: [other_grade.id])
        test_setting = build(:test_setting, :general_by_school,
                             year: 2026,
                             unities: [shared_unity.id, other_unity.id],
                             grades: [shared_grade.id, other_grade.id])

        expect(test_setting).to_not be_valid
        expect(test_setting.errors[:grades]).to eq(
          ['As séries 1º ano - Ensino Fundamental e 2º ano - Ensino Fundamental já estão em outra configuração ' \
           'de 2026 para as escolas Escola Centro e Escola Norte']
        )
      end

      it 'summarizes long lists of grades and unities' do
        unities = %w[Alfa Beta Delta Gama].map { |suffix| create(:unity, name: "Escola #{suffix}") }
        grades = (1..4).map { |number| create(:grade, description: "#{number}º ano", course: course) }
        create(:test_setting, :general_by_school, year: 2030, unities: unities.map(&:id), grades: grades.map(&:id))
        test_setting = build(:test_setting, :general_by_school,
                             year: 2030,
                             unities: unities.map(&:id),
                             grades: grades.map(&:id))

        expect(test_setting).to_not be_valid
        expect(test_setting.errors[:grades]).to eq(
          ['As séries 1º ano - Ensino Fundamental, 2º ano - Ensino Fundamental, 3º ano - Ensino Fundamental ' \
           'e mais 1 já estão em outra configuração de 2030 ' \
           'para as escolas Escola Alfa, Escola Beta, Escola Delta e mais 1']
        )
      end

      it 'names discarded grades, courses and unities still referenced by the other setting' do
        closed_course = create(:course, description: 'Curso Extinto')
        closed_grade = create(:grade, description: '9º ano', course: closed_course)
        closed_unity = create(:unity, name: 'Escola Fechada')
        create(:test_setting, :general_by_school, year: 2031, unities: [closed_unity.id], grades: [closed_grade.id])
        [closed_course, closed_grade, closed_unity].each(&:discard)
        test_setting = build(:test_setting, :general_by_school,
                             year: 2031,
                             unities: [closed_unity.id],
                             grades: [closed_grade.id])

        expect(test_setting).to_not be_valid
        expect(test_setting.errors[:grades]).to eq(
          ['A série 9º ano - Curso Extinto já está em outra configuração de 2031 para a escola Escola Fechada']
        )
      end

      it 'allows another setting for the same unity with a different grade' do
        test_setting = build(:test_setting, :general_by_school,
                             year: 2026,
                             unities: [shared_unity.id],
                             grades: [other_grade.id])

        expect(test_setting).to be_valid
      end

      it 'allows another setting for a different unity with the same grade' do
        test_setting = build(:test_setting, :general_by_school,
                             year: 2026,
                             unities: [other_unity.id],
                             grades: [shared_grade.id])

        expect(test_setting).to be_valid
      end

      it 'allows another setting for the same unity and grade in a different year' do
        test_setting = build(:test_setting, :general_by_school,
                             year: 2027,
                             unities: [shared_unity.id],
                             grades: [shared_grade.id])

        expect(test_setting).to be_valid
      end

      # grades vazio significa "todas as séries": qualquer série da mesma unidade colide
      it 'does not allow another setting covering all grades of the same unity' do
        test_setting = build(:test_setting, :general_by_school,
                             year: 2026,
                             unities: [shared_unity.id],
                             grades: [])

        expect(test_setting).to_not be_valid
        expect(test_setting.errors[:grades]).to eq(
          ['A série 1º ano - Ensino Fundamental já está em outra configuração de 2026 para a escola Escola Centro']
        )
      end

      it 'does not allow two settings covering all grades of the same unity' do
        create(:test_setting, :general_by_school, year: 2026, unities: [other_unity.id], grades: [])
        test_setting = build(:test_setting, :general_by_school,
                             year: 2026,
                             unities: [other_unity.id],
                             grades: [])

        expect(test_setting).to_not be_valid
        expect(test_setting.errors[:grades]).to eq(
          ['Todas as séries já estão em outra configuração de 2026 para a escola Escola Norte']
        )
      end

      # a coluna aceita NULL: a busca só retorna esse legado quando a nova configuração cobre todas as séries
      it 'keeps blocking all grades against a legacy setting with null grades' do
        create(:test_setting, :general_by_school, year: 2026, unities: [other_unity.id], grades: nil)
        test_setting = build(:test_setting, :general_by_school, year: 2026, unities: [other_unity.id], grades: [])

        expect(test_setting).to_not be_valid
        expect(test_setting.errors[:grades]).to eq(
          ['Todas as séries já estão em outra configuração de 2026 para a escola Escola Norte']
        )
      end
    end

    context 'when sum calculation type' do
      before { subject.average_calculation_type = AverageCalculationTypes::SUM }

      it 'validates at least one assigned test' do
        subject.tests = []

        expect(subject).to_not be_valid
        expect(subject.errors.messages[:tests]).to include('É necessário pelo menos uma avaliação')
      end

      context 'when there are assigned tests' do
        before { subject.tests << FactoryGirl.build(:test_setting_test, weight: 101) }
        it 'they should be less or equal to maximum score' do
          subject.maximum_score = 100
          expect(subject).to_not be_valid
          expect(subject.errors.messages[:tests]).to include('A soma dos pesos das avaliações deve resultar em um valor menor ou igual da nota máxima')
        end
      end
    end
  end

  describe 'default values' do
    subject { TestSetting.new }

    it { expect(subject.maximum_score).to eq(10) }
    it { expect(subject.number_of_decimal_places).to eq(2) }
  end
end

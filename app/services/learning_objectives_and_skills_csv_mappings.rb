# frozen_string_literal: true

module LearningObjectivesAndSkillsCsvMappings
  DISCIPLINE_MAPPINGS = {
    'lingua portuguesa' => 'portuguese_language',
    'arte' => 'art',
    'educacao fisica' => 'physical_education',
    'lingua inglesa' => 'english_language',
    'lingua espanhola' => 'spanish_language',
    'matematica' => 'mathematics',
    'ciencias' => 'sciences',
    'geografia' => 'geography',
    'historia' => 'history',
    'ensino religioso' => 'religious_education',
    'lingua italiana' => 'italian_language',
    'computacao' => 'computing'
  }.freeze

  EXPERIENCE_FIELD_MAPPINGS = {
    'o eu o outro e o nos' => 'the_me_the_other_and_the_us',
    'corpo gestos e movimentos' => 'body_gestures_and_movements',
    'tracos sons cores e formas' => 'strokes_sounds_colors_and_shapes',
    'tracos sons cores e forma' => 'strokes_sounds_colors_and_shapes',
    'escuta fala pensamento e imaginacao' => 'listening_speaking_thinking_and_imagining',
    'espacos tempos quantidades relacoes e transformacoes' =>
      'spaces_times_quantities_relationships_and_transformations',
    'computacao' => 'computing'
  }.freeze

  STEP_MAPPINGS = {
    'ensino fundamental' => 'elementary_school',
    'educacao infantil' => 'child_school',
    'educacao para jovens e adultos' => 'adult_and_youth_education'
  }.freeze

  GRADE_MAPPINGS = {
    '1 ano' => 'first_year',
    '1o ano' => 'first_year',
    '2 ano' => 'second_year',
    '2o ano' => 'second_year',
    '3 ano' => 'third_year',
    '3o ano' => 'third_year',
    '4 ano' => 'fourth_year',
    '4o ano' => 'fourth_year',
    '5 ano' => 'fifth_year',
    '5o ano' => 'fifth_year',
    '6 ano' => 'sixth_year',
    '6o ano' => 'sixth_year',
    '7 ano' => 'seventh_year',
    '7o ano' => 'seventh_year',
    '8 ano' => 'eighth_year',
    '8o ano' => 'eighth_year',
    '9 ano' => 'ninth_year',
    '9o ano' => 'ninth_year',
    '1 ano eja' => 'eja_first_year',
    '1o ano eja' => 'eja_first_year',
    '2 ano eja' => 'eja_second_year',
    '2o ano eja' => 'eja_second_year',
    '3 ano eja' => 'eja_third_year',
    '3o ano eja' => 'eja_third_year',
    '4 ano eja' => 'eja_fourth_year',
    '4o ano eja' => 'eja_fourth_year',
    '5 ano eja' => 'eja_fifth_year',
    '5o ano eja' => 'eja_fifth_year',
    '6 ano eja' => 'eja_sixth_year',
    '6o ano eja' => 'eja_sixth_year',
    '7 ano eja' => 'eja_seventh_year',
    '7o ano eja' => 'eja_seventh_year',
    '8 ano eja' => 'eja_eighth_year',
    '8o ano eja' => 'eja_eighth_year',
    '9 ano eja' => 'eja_ninth_year',
    '9o ano eja' => 'eja_ninth_year',
    'creche 0 a 1 ano e 6 meses' => 'nursery_1',
    'creche 1 ano e 7 meses a 3 anos e 11 meses' => 'nursery_2',
    'pre escola 4 a 5 anos' => 'preschool',
    'pre escola 4 a 5 ano' => 'preschool',
    'grupo 1 bebe 0 a 11 meses' => 'group_1',
    'grupo 2 cbp 1 ano a 1 anos 11 meses' => 'group_2',
    'grupo 3 cbp 2 anos a 2 anos e 11 meses' => 'group_3',
    'grupo 4 cbp 3 anos a 3 anos e 11 meses' => 'group_4',
    'grupo 5 cp 4 anos a 4 anos e 11 meses' => 'group_5',
    'grupo 6 cp 5 anos a 5 anos a 11 meses' => 'group_6'
  }.freeze

  GRADES_BY_STEP = {
    'child_school' => %w[
      nursery_1 nursery_2 preschool
      group_1 group_2 group_3 group_4 group_5 group_6
    ].freeze,
    'elementary_school' => %w[
      first_year second_year third_year fourth_year fifth_year
      sixth_year seventh_year eighth_year ninth_year
    ].freeze,
    'adult_and_youth_education' => %w[
      eja_first_year eja_second_year eja_third_year eja_fourth_year eja_fifth_year
      eja_sixth_year eja_seventh_year eja_eighth_year eja_ninth_year
    ].freeze
  }.freeze

  def normalize(value)
    normalized = value.to_s.strip.gsub('º', 'o').gsub('ª', 'a')
    I18n.transliterate(normalized.gsub(/[.,;:\-_()]/, ' ')).downcase.squish
  end

  def match_discipline(raw_value)
    return nil if raw_value.blank?

    DISCIPLINE_MAPPINGS[normalize(raw_value)]
  end

  def match_experience_field(raw_value)
    return nil if raw_value.blank?

    EXPERIENCE_FIELD_MAPPINGS[normalize(raw_value)]
  end

  def match_step(raw_value)
    return nil if raw_value.blank?

    STEP_MAPPINGS[normalize(raw_value)]
  end

  def match_grade(raw_value)
    return nil if raw_value.blank?

    GRADE_MAPPINGS[normalize(raw_value)]
  end

end

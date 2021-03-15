class ScoreRounder
  def initialize(classroom, rounded_avaliation)
    @classroom = classroom
    @rounded_avaliation = rounded_avaliation
  end

  def round(score)
    return if score.nil?

    score_decimal_part = decimal_part(score)
    rounding_table_value = custom_rounding_table_value(score_decimal_part)
    rounded_score = rounded_score_by_action(score, rounding_table_value)

    truncate_score(rounded_score.to_f)
  end

  private

  def rounded_score_by_action(score, rounding_table_value)
    return score unless score.is_a?(Numeric)

    rounded_score = score

    if rounding_table_value.present?
      rounded_score = case rounding_table_value.action
                      when RoundingTableAction::NONE
                        score
                      when RoundingTableAction::BELOW
                        round_to_below(score)
                      when RoundingTableAction::ABOVE
                        round_to_above(score)
                      when RoundingTableAction::SPECIFIC
                        round_to_exact_decimal(score, rounding_table_value.exact_decimal_place)
                      end
    end

    rounded_score
  end

  def custom_rounding_table_value(score_decimal_part)
    rounding_table_id = custom_rounding_table_id

    return if rounding_table_id.blank?

    CustomRoundingTableValue.find_by(
      custom_rounding_table_id: rounding_table_id,
      label: score_decimal_part
    )
  end

  def custom_rounding_table_id
    CustomRoundingTable.by_year(@classroom.year)
                       .by_unity(@classroom.unity_id)
                       .by_grade(@classroom.grade_id)
                       .by_avaliation(@rounded_avaliation)
                       .first.try(:id)
  end

  def decimal_part(value)
    parts = value.to_s.split('.')
    decimal_part = parts.count > 1 ? parts[1][0].to_s : 0

    decimal_part
  end

  def round_to_exact_decimal(score, exact_decimal_place)
    "#{score.floor}.#{exact_decimal_place}".to_f
  end

  def round_to_above(score)
    score.ceil
  end

  def round_to_below(score)
    score.floor
  end

  def truncate_score(score)
    parts = score.to_s.split('.')
    integer_part = parts[0]
    decimal_part = parts[1][0]

    "#{integer_part}.#{decimal_part}".to_f
  end
end

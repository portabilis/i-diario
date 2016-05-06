class ScoreRounder

  def initialize(exam_rule)
    raise ArgumentError unless exam_rule
    @exam_rule = exam_rule
  end

  def round(score)
    return 10.0 if score == 10
    score_decimal_part = decimal_part(score)
    rounding_table_id = exam_rule_rounding_table.try(:id)
    rounding_table_value = RoundingTableValue.find_by(rounding_table_id: rounding_table_id, label: score_decimal_part)

    rounded_score = score
    if rounding_table_value
      case rounding_table_value.action
      when RoundingTableAction::NONE
        rounded_score = score
      when RoundingTableAction::BELOW
        rounded_score = round_to_below(score)
      when RoundingTableAction::ABOVE
        rounded_score = round_to_above(score)
      when RoundingTableAction::SPECIFIC
        rounded_score = round_to_exact_decimal(score, rounding_table_value.exact_decimal_place)
      end
    end

    truncate_score(rounded_score.to_f)
  end

  private

  attr_accessor :exam_rule

  delegate :rounding_table, to: :exam_rule, prefix: true, allow_nil: true

  def decimal_part(value)
    parts = value.to_s.split(".")
    decimal_part = parts.count > 1 ? parts[1][0].to_s : 0
    decimal_part
  end

  def round_to_exact_decimal(score, exact_decimal_place)
    (score.floor.to_s + "." + exact_decimal_place.to_s).to_f
  end

  def round_to_above(score)
    score.ceil
  end

  def round_to_below(score)
    score.floor
  end

  def truncate_score(score)
    parts = score.to_s.split(".")
    decimal_part = parts.count > 1 ? parts[1][0].to_s : 0
    integer_part = parts.count > 1 ? parts[0][0].to_s : 0
    (integer_part + "." + decimal_part).to_f
  end

end

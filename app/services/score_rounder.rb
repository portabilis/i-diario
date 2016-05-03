class ScoreRounder

  def initialize(exam_rule)
    raise ArgumentError unless exam_rule
    @exam_rule = exam_rule
  end

  def round(score)
    return score unless exam_rule_rounding_table_values.any?
    score_decimal_part = decimal_part(score)
    rounded_score = score
    exam_rule_rounding_table_values.each do |value|
      if score_decimal_part == value.label
        case value.action
        when RoundingTableAction::NONE
          rounded_score = score
        when RoundingTableAction::BELOW
          rounded_score = round_to_below(score)
        when RoundingTableAction::ABOVE
          rounded_score = round_to_above(score)
        when RoundingTableAction::SPECIFIC
          rounded_score = round_to_exact_decimal(score, value.exact_decimal_place)
        else
          rounded_score = score
        end
      end
    end
    return rounded_score.to_f
  end

  private

  attr_accessor :exam_rule

  delegate :rounding_table, to: :exam_rule, prefix: true, allow_nil: true
  delegate :values, to: :exam_rule_rounding_table, prefix: true, allow_nil: true

  def decimal_part(value)
    parts = value.to_s.split(".")
    decimal_part = parts.count > 1 ? parts[1][0].to_s : 0
    return decimal_part
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
    return (integer_part + "." + decimal_part).to_f
  end

end

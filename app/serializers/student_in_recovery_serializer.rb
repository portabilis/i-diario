class StudentInRecoverySerializer < ActiveModel::Serializer
  attributes :id, :name, :average,
             :active, :dependence, :exempted_from_discipline, :in_active_search

  def id
    object.student.id
  end

  def name
    object.student.to_s
  end

  def average
    avg = StudentRecoveryAverageCalculator.new(
      object.student,
      @serialization_options[:classroom],
      @serialization_options[:discipline],
      @serialization_options[:step]
    ).recovery_average

    return nil if avg.blank?

    "%.#{@serialization_options[:number_of_decimal_places]}f" % avg
  end

  def active
    @serialization_options[:active_enrollment_ids].include?(object.id)
  end

  def dependence
    @serialization_options[:dependencies][object.id].present?
  end

  def exempted_from_discipline
    @serialization_options[:exemptions][object.id].present?
  end

  def in_active_search
    @serialization_options[:active_search_enrollment_ids].include?(object.id)
  end
end

class AvaliationSerializer < ActiveModel::Serializer
  attributes :id, :description_to_teacher, :test_date, :description, :classroom,
             :discipline, :test_date_humanized, :test_date_today, :to_s

   def to_s
     object.to_s
   end

  def description
    to_s
  end
end

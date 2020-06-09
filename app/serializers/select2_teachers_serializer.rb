class Select2TeachersSerializer < ActiveModel::Serializer
  self.root = 'results'

  attributes :id, :name, :text

  def name
    object.to_s
  end

  def text
    object.to_s
  end
end

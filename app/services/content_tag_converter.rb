class ContentTagConverter
  def self.tags_to_contents(tags)
    tags.split(',').reject(&:empty?).map { |description| Content.find_or_create_by!(description: description) }
  end

  def self.contents_to_json(contents)
    return '[]' if contents.blank?

    contents.map { |content| { id: content.description, text: content.description } }.to_json
  end

  def self.tags_to_json(tags)
    return '[]' if tags.blank?

    tags.split(',').map { |tag| { id: tag, text: tag } }.to_json
  end
end

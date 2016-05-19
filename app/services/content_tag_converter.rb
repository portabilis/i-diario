class ContentTagConverter
  def self.tags_to_contents(tags)
    tags.split(",").reject(&:empty?).map{|description| Content.find_or_create_by!(description: description)}
  end

  def self.contents_to_tags(contents)
    return "" if contents.blank?
    contents.map(&:description).join(",")
  end
end

class ObjectivesToContentFetcher
  def initialize(code)
    @code = code
  end

  def self.fetch(code)
    new(code).fetch
  end

  def fetch
    LearningObjectivesAndSkill
      .by_code(@code)
      .select(
       " '(' || learning_objectives_and_skills.code || ') ' || learning_objectives_and_skills.description as description"
      )
  end
end

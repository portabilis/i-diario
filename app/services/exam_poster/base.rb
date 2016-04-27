module ExamPoster
  class Base
    attr_accessor :warning_messages

    def initialize(post_data)
      @post_data = post_data
      @warning_messages = []
    end

    def post!
      raise NotImplementedError
    end

  end
end

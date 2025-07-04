module IeducarApi
  class PostRequestService
    def initialize(posting)
      @posting = posting
    end

    def execute(params, info)
      params = params.with_indifferent_access
      information = InfoMessageBuilder.new(info).build

      begin
        response = IeducarResponseDecorator.new(api_client.send_post(params))
        handle_response(response, information)
      rescue StandardError => error
        ErrorHandlerService.new(posting).handle(error, information)
      end
    end

    private

    attr_reader :posting

    def api_client
      @api_client ||= create_api_client
    end

    def create_api_client
      case posting.post_type
      when ApiPostingTypes::NUMERICAL_EXAM
        IeducarApi::PostExams.new(posting.to_api)
      when ApiPostingTypes::CONCEPTUAL_EXAM
        IeducarApi::PostExams.new(posting.to_api)
      when ApiPostingTypes::DESCRIPTIVE_EXAM
        IeducarApi::PostDescriptiveExams.new(posting.to_api)
      when ApiPostingTypes::ABSENCE
        IeducarApi::PostAbsences.new(posting.to_api)
      when ApiPostingTypes::FINAL_RECOVERY
        IeducarApi::FinalRecoveries.new(posting.to_api)
      when ApiPostingTypes::SCHOOL_TERM_RECOVERY
        IeducarApi::PostRecoveries.new(posting.to_api)
      else
        raise ArgumentError, "Tipo de postagem não suportado: #{posting.post_type}"
      end
    end

    def handle_response(response, information)
      if response.any_error_message?
        posting.add_warning!(response.full_error_message(information))
      end
    end
  end
end

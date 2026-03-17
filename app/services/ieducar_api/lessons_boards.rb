module IeducarApi
  class LessonsBoards < Base
    def fetch(params = {})
      raise ApiError, 'É necessário informar o ano' if params[:year].blank?
      raise ApiError, 'É necessário informar pelo menos uma escola' if params[:school_id].blank?

      endpoint = [url, 'api/v3/school-class'].join('/')

      query_params = {
        'filter[school]' => params[:school_id],
        'filter[year]' => params[:year],
        include: 'timetable.slots'
      }

      fetch_v3(
        endpoint,
        query_params,
      )
    end
  end
end

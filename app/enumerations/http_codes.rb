class HttpCodes < EnumerateIt::Base
  associate_values not_found: '404',
                   unprocessable_entity: '422',
                   internal_server_error: '500'

  sort_by :none
end

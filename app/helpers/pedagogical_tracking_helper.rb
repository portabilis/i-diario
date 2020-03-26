module PedagogicalTrackingHelper
  def link_params(record)
    params = if record.classroom_id.present?
               { 'search[classroom_id]': record.classroom_id }
             else
               { 'search[unity_id]': record.unity_id }
             end

    params.merge!('search[start_date]': format(record.start_date), 'search[end_date]': format(record.end_date))
  end

  def format(date)
    date.strftime('%d/%m/%Y')
  end
end

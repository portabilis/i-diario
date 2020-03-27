module PedagogicalTrackingHelper
  def link_params(record)
    {
      'search[unity_id]': record.unity_id,
      'search[start_date]': format(record.start_date),
      'search[end_date]': format(record.end_date)
    }
  end

  def format(date)
    date.strftime('%d/%m/%Y')
  end
end

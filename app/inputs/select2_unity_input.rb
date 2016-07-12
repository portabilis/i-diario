class Select2UnityInput < Select2Input

  def input(wrapper_options)
    raise "User must be passed" unless options[:user].is_a? User

    input_html_options[:readonly] = 'readonly'
    input_html_options[:value] = options[:user].try(:current_unity).try(:id)
    super(wrapper_options)
  end

  def parse_collection
    user = options[:user]

    unities = []

    unities << user.current_unity if user.current_unity.present?

    options[:elements] = unities
    super
  end
end

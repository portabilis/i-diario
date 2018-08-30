class Select2StepInput < Select2Input
  def input(wrapper_options)
    raise 'Classroom must be passed' unless options[:classroom].is_a? Classroom

    super(wrapper_options)
  end

  def parse_collection
    options[:elements] = StepsFetcher.new(options[:classroom]).steps

    super
  end
end

class AdminFormBuilder < ActionView::Helpers::FormBuilder
  def technical_field(method, options = {})
    options[:class] = 'form-control technical-input'
    options = objectify_options(options)
    if options.fetch(:rows, nil) == 1
      return @template.text_field @object_name, method, options
    end

    # rows:
    attr_value = options[:value] || options[:object].send(method)
    if attr_value.is_a?(Array)
      options[:rows] = calc_row_count(options[:rows], attr_value.size)
      options[:value] = attr_value.join(', ')
    elsif attr_value.is_a?(String)
      options[:rows] = calc_row_count(
        options[:rows], attr_value.to_s.split("\n").size)
    end

    @template.text_area @object_name, method, options
  end

  def list_as_lines(method, options = {})
    options = objectify_options(options)
    attr_value = options[:object].send(method)
    options[:class] = 'form-control technical-input'
    options[:value] = attr_value.try(:join, "\n")
    options[:rows] = calc_row_count(options[:rows] || 5, attr_value.try(:size))
    @template.text_area @object_name, method, options
  end

  private

  def calc_row_count(given_row_count, content_length)
    default_row_count = 12
    [[default_row_count, given_row_count].map(&:to_i).min, content_length.to_i].max
  end
end

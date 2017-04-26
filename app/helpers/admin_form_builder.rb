class AdminFormBuilder < ActionView::Helpers::FormBuilder
  def technical_field(method, options = {})
    options[:class] = 'form-control technical-input'
    options = objectify_options(options)
    if options.fetch(:rows, nil) == 1
      return @template.text_field @object_name, method, options
    end

    unless options.key?(:rows)
      attr_value = options[:object].send(method)

      if attr_value.is_a?(Array)
        options[:rows] = attr_value.size
        options[:value] = attr_value.join(', ')
      elsif attr_value.is_a?(String)
        options[:rows] = attr_value.to_s.split("\n").size
      end
    end
    @template.text_area @object_name, method, options
  end
end

module FormsHelper
  def unescaped_hidden_field_tag(name, value = nil)
    capture_haml do
      content_tag :input, nil, type: :hidden, name: name, value: value
    end
  end
end

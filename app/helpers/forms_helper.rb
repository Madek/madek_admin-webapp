module FormsHelper
  def unescaped_hidden_field_tag(name, value = nil)
    capture_haml do
      haml_tag :input, type: :hidden, name: name, value: value
    end
  end
end

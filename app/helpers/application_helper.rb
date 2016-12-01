module ApplicationHelper
  def markdown(source)
    Kramdown::Document.new(source).to_html.html_safe
  end

  def navbar_item(text, path)
    content_tag :li, class: ('active' if current_page?(path)) do
      link_to text, path
    end
  end

  def alerts
    flash.each do |level, message|
      bootstrap_level = (level.to_sym == :error) ? :danger : level
      yield level, message, bootstrap_level if message
    end
    nil
  end

  def filter_options_for_select(container)
    options_for_select(container)
  end

  def default_filter_option
    content_tag :option, '(all)', value: ''
  end
end

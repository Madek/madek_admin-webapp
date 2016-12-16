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

  def self.unwrap_and_hide_secrets(ostruct, blacklist:)
    ostruct.marshal_dump.map do |key, val|
      if val.is_a?(OpenStruct) # recurse
        [key, unwrap_and_hide_secrets(val, blacklist: blacklist)]
      elsif blacklist.any? { |s| key.to_s.include?(s) }
        [key, obfuscate_secret(val)]
      else
        [key, val]
      end
    end.to_h.compact
  end

  def self.obfuscate_secret(string)
    Array.new(string.try(:to_s).try(:length) || 3) { '*' }.join
  end

end

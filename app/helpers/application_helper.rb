module ApplicationHelper
  include UiHelper

  def markdown(source)
    return '' if source.blank?
    Kramdown::Document.new(source).to_html.html_safe
  end

  def navbar_item(text, path)
    content_tag :li, nil, class: ('active' if current_page?(path)) do
      link_to text, path
    end
  end

  def alerts
    flash.each do |level, message|
      bootstrap_level = level.to_sym == :error ? :danger : level
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

  def icon(name)
    throw ArgumentError unless name.present?
    capture_haml do
      content_tag('i', nil, class: "glyphicon glyphicon-#{name}", aria: { hidden: true })
    end
  end

  def webapp_keyword_path(keyword)
    meta_key = MetaKey
                .viewable_by_user_or_public(current_user)
                .where(id: keyword.meta_key_id)
                .first
    if meta_key.present?
      '/vocabulary/$meta_key_id/terms/$keyword_term'
        .gsub('$meta_key_id', meta_key.id)
        .gsub('$keyword_term', ERB::Util.url_encode(keyword.term))
    else
      false
    end
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

  def empty_collection(collection_name, colspan)
    content_tag :tr, nil, class: 'empty-collection' do
      content_tag(:td,
                  "No #{collection_name}",
                  colspan: colspan,
                  class: 'text-center')
    end
  end

  def parse_external_uris(text)
    return [] unless text.present? and text.is_a?(String)
    URI.extract(text).map do |line|
      begin
        uri = URI.parse(line)
        uri.user = nil
        uri.password = nil
        uri
      rescue
        nil
      end
    end.map(&:to_s).map(&:presence).compact
  end

end

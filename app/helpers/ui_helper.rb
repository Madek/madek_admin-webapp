# rubocop:disable Metrics/MethodLength
module UiHelper

  def data_table(data)
    capture_haml do
      content_tag('table', nil, class: ['table', 'table-condensed', 'code-table']) do
        data.map do |title, hash|
          thead = content_tag('thead') do
            th1 = content_tag('th') { content_tag('div', nil, class: 'h5') { concat title } }
            th2 = content_tag('th')
            th1 + th2
          end
          tbody = content_tag('tbody') do
            hash.map do |key, val|
              content_tag('tr') do
                th = content_tag('th') { content_tag('samp') { concat key } }
                td = content_tag('td') do
                  val = JSON.pretty_generate(val) if val.is_a?(Hash) || val.is_a?(Array)
                  content_tag('samp') { concat val }
                end
                th + td
              end
            end.reduce(:+)
          end
          thead + tbody
        end.reduce(:+)
      end
    end
  end

  def admin_comment_row(object, colspan:, striped: nil)
    render partial: 'shared/admin_comment_row',
           locals: { object: object, striped: striped, colspan: colspan }
  end

  def admin_comment(object)
    comment =
      if object.admin_comment.present?
        object.admin_comment.truncate_words(16)
      else
        '<em>none</em>'
      end
    if comment.ends_with?('...')
      comment = [
        comment,
        link_to('See more', url_for(controller: object.class.name.tableize,
                                    action: :show,
                                    id: object.id,
                                    only_path: true))
      ].join(' ')
    end
    comment.html_safe
  end
end

# rubocop:disable Metrics/MethodLength
module UiHelper

  def data_table(data, *args)
    capture_haml do
      content_tag 'table.table.table-condensed', *args do
        data.each do |title, hash|
          content_tag('thead') do
            content_tag('th') { content_tag('.h5') { concat title } }
            content_tag('th')
          end
          content_tag 'tbody' do
            hash.each do |key, val|
              content_tag 'tr' do
                content_tag('th') { content_tag('samp') { concat key } }
                content_tag('td') do
                  val = JSON.pretty_generate(val) if val.is_a?(Hash) || val.is_a?(Array)
                  content_tag('samp') { concat val }
                end
              end
            end
          end
        end
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

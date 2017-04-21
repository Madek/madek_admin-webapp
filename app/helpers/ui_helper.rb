# rubocop:disable Metrics/LineLength
# rubocop:disable Metrics/MethodLength
module UiHelper

  def data_table(data, *args)
    capture_haml do
      haml_tag 'table.table.table-condensed', *args do
        data.each do |title, hash|
          haml_tag('thead') do
            haml_tag('th') { haml_concat title }
            haml_tag('th')
          end
          haml_tag 'tbody' do
            hash.each do |key, val|
              haml_tag 'tr' do
                haml_tag('th') { haml_tag('samp') { haml_concat key } }
                haml_tag('td') do
                  val = JSON.pretty_generate(val) if val.is_a?(Hash) || val.is_a?(Array)
                  haml_tag('samp') { haml_concat val }
                end
              end
            end
          end
        end
      end
    end
  end

end

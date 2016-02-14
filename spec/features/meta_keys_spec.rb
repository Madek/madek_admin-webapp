require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Meta Keys' do
  let(:meta_key_with_keywords) { MetaKey.with_type('MetaDatum::Keywords').first }
  let(:vocabulary) { Vocabulary.find('archhist') }

  scenario 'Sorting meta keys by ID by default' do
    visit meta_keys_path

    expect(find_field('sort_by')[:value]).to eq 'id'
  end

  scenario 'Sorting meta keys by Name part' do
    visit meta_keys_path

    select 'Name part', from: 'Sort by'
    click_button 'Apply'

    expect(page).to have_select('sort_by', selected: 'Name part')
  end

  context 'Editing' do
    scenario 'Proper values for selects' do
      visit edit_meta_key_path(meta_key_with_keywords)

      expect(page).to have_select(
        'Vocabulary',
        selected: meta_key_with_keywords.vocabulary_id)
      expect(page).to have_select(
        'Meta datum object type',
        selected: meta_key_with_keywords.meta_datum_object_type)
      expect(page).to have_select(
        'Keywords alphabetical order',
        selected: selected_value_from_boolean(
          meta_key_with_keywords.keywords_alphabetical_order)
      )
    end
  end

  scenario 'Changing position in scope of a vocabulary' do
    visit vocabulary_path(vocabulary)

    click_link 'Edit'

    expect_order %w(archhist:ca_thema
                    archhist:ca_zweck
                    archhist:ca_kontext
                    archhist:ca_ausgangsmaterial)

    within find('table tr[data-id="archhist:ca_thema"]') do
      find('.move-down').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist:ca_zweck
                    archhist:ca_thema
                    archhist:ca_kontext
                    archhist:ca_ausgangsmaterial)

    within find('table tbody tr[data-id="archhist:ca_kontext"]') do
      find('.move-up').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(archhist:ca_zweck
                    archhist:ca_kontext
                    archhist:ca_thema
                    archhist:ca_ausgangsmaterial)
  end

  def expect_order(order, limit = 4)
    expect(
      all('table tr[data-id]').map { |tr| tr['data-id'] }[0, limit]
    ).to eq(order)
  end

  def selected_value_from_boolean(value)
    value == true ? 'Yes' : 'No'
  end
end

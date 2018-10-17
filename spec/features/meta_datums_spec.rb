require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Meta Datums' do
  scenario 'has meta datums table' do
    visit meta_datums_path

    expect(page).to have_content("Meta Datums (#{MetaDatum.count})")
    expect(page).to have_css('table tbody tr', count: 16)
  end

  scenario 'has filter by type' do
    visit meta_datums_path

    expect(page).to have_content('Filters')
    expect(page).to have_select('type', with_options: MetaKey.object_types)
  end

  context 'filtering meta datums' do
    let!(:meta_datum) { create :meta_datum_title, string: 'foo bar' }

    scenario 'filtering by ID' do
      visit meta_datums_path

      fill_in 'search_term', with: meta_datum.id
      click_button 'Apply'

      expect(page).to have_css('table tbody tr', text: meta_datum.id)
      expect(page).to have_css('table tbody tr', text: 'foo bar')
      expect(page).to have_field('search_term', with: meta_datum.id)
      expect(page).to have_content('Meta Datums (1)')
    end

    scenario 'filtering by string' do
      visit meta_datums_path

      fill_in 'search_term', with: 'o b'
      select 'String', from: 'search_by'
      click_button 'Apply'

      expect(page).to have_css('table tbody tr', text: meta_datum.id)
      expect(page).to have_css('table tbody tr', text: 'foo bar')
      expect(page).to have_field('search_term', with: 'o b')
    end

    scenario 'filtering by type' do
      visit meta_datums_path

      select 'MetaDatum::Text', from: 'type'
      click_button 'Apply'

      expect(page).to have_css('table tbody tr',
                               text: 'MetaDatum::Text',
                               count: 16)
      expect(page).to have_select('type', selected: 'MetaDatum::Text')
    end
  end

  scenario 'linking to a Meta Key' do
    visit meta_datums_path

    anchor = find('a.meta-key', match: :first)
    meta_key = MetaKey.find(anchor.text)

    anchor.click

    expect(current_path).to eq meta_key_path(meta_key.id)
    expect(page).to have_content "Meta Key #{meta_key.id}"
  end

  scenario 'linking to a Vocabulary' do
    visit meta_datums_path

    anchor = find('a', text: 'Vocabulary', match: :first)
    vocabulary = Vocabulary.find(id_from_path(anchor))

    anchor.click

    expect(current_path).to eq vocabulary_path(vocabulary.id)
    expect(page).to have_content "Vocabulary: #{vocabulary.id}"
  end

  scenario 'linking to a Media Entry' do
    visit meta_datums_path

    anchor = find('a', text: 'Media Entry', match: :first)
    media_entry = MediaEntry.find(id_from_path(anchor))

    anchor.click

    expect(current_path).to eq media_entry_path(media_entry.id)
    expect(page).to have_content "Media Entry: #{media_entry.title}"
  end

  scenario 'linking to a Collection' do
    meta_datum = create :meta_datum_title_with_collection

    visit meta_datums_path

    fill_in 'search_term', with: meta_datum.id
    click_button 'Apply'
    click_link 'Collection'

    expect(current_path).to eq collection_path(meta_datum.collection.id)
    expect(page).to have_content meta_datum.collection.title
  end

  def id_from_path(anchor)
    anchor[:href].split('/').last
  end
end

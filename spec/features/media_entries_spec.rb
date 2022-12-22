require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Media Entries' do
  let!(:not_published_media_entry) do
    create(:media_entry, is_published: false)
  end

  let!(:media_entry_of_a_delegation) do
    create(:media_entry_with_image_media_file,
           is_published: false,
           responsible_delegation: create(:delegation),
           responsible_user: nil)
  end

  scenario 'linking to Meta Datums list' do
    media_entry = MediaEntry.first
    visit media_entry_path(media_entry)

    expect(page).to have_content "Media Entry: #{media_entry.title}"

    click_link "Meta Datums: #{media_entry.meta_data.count}"

    expect(current_path).to eq meta_datums_path
    expect(page).to have_field('search_term', with: media_entry.id)
    expect(page).to have_select('search_by', selected: 'Media Entry ID')
    expect(page).to have_content "Meta Datums (#{media_entry.meta_data.count})"
  end

  scenario 'Filtering by is_published attribute', browser: :firefox do
    visit media_entries_path

    expect(page).to have_select(
      'filter[is_published]',
      selected: 'Published & not published'
    )
    click_link 'Last'
    expect(page).to have_css "tr[data-id='#{not_published_media_entry.id}']"

    select 'Published', from: 'filter[is_published]'
    click_button 'Apply'
    expect(page).to have_select(
      'filter[is_published]',
      selected: 'Published'
    )
    click_link 'Last'
    expect(page).not_to have_css "tr[data-id='#{not_published_media_entry.id}']"

    select 'Not published', from: 'filter[is_published]'
    click_button 'Apply'
    expect(page).to have_select(
      'filter[is_published]',
      selected: 'Not published'
    )
    expect(page).to have_css "tr[data-id='#{not_published_media_entry.id}']"
  end

  scenario 'Searching for an entry of a delegation renders without error' do
    visit media_entries_path
    fill_in "search_term", with: media_entry_of_a_delegation.id
    click_button 'Apply'
    expect(page).to have_css "tr[data-id='#{media_entry_of_a_delegation.id}']"
  end

  scenario 'Show page of an entry from a delegation renders without error' do
    visit media_entry_path(media_entry_of_a_delegation)
    expect(page).to have_content media_entry_of_a_delegation.title
  end
end

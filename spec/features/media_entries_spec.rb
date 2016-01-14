require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Meta Entries' do
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
end

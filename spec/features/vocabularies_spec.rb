require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Vocabularies' do
  let(:vocabulary) { create :vocabulary }

  scenario 'Editing a vocabulary' do
    visit vocabularies_path

    filter(vocabulary.id)

    within "[data-id='#{vocabulary.id}']" do
      click_link 'Edit'
    end

    expect(current_path).to eq edit_vocabulary_path(vocabulary)
    expect(page).to have_checked_field 'vocabulary[enabled_for_public_view]'
    expect(page).to have_checked_field 'vocabulary[enabled_for_public_use]'

    fill_in 'vocabulary[label]', with: 'new label'
    fill_in 'vocabulary[description]', with: 'new description'
    uncheck 'vocabulary[enabled_for_public_view]'
    uncheck 'vocabulary[enabled_for_public_use]'

    click_button 'Save'

    expect(current_path).to eq vocabulary_path(vocabulary)
    expect(page).to have_content 'Label new label'
    expect(page).to have_content 'Description new description'
    expect(page).to have_content 'Enabled for public view false'
    expect(page).to have_content 'Enabled for public use false'
  end

  def filter(search_term)
    fill_in 'search_term', with: search_term
    click_button 'Apply'
  end
end

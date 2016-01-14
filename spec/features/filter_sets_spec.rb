require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Filter Sets' do
  scenario 'linking to Meta Datums list' do
    filter_set = FilterSet.first
    visit filter_set_path(filter_set)

    expect(page).to have_content filter_set.title

    click_link "Meta Datums: #{filter_set.meta_data.count}"

    expect(current_path).to eq meta_datums_path
    expect(page).to have_field('search_term', with: filter_set.id)
    expect(page).to have_select('search_by', selected: 'Filter Set ID')
    expect(page).to have_content "Meta Datums (#{filter_set.meta_data.count})"
  end
end

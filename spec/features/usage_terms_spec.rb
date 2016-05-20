require 'spec_helper'
require 'spec_helper_feature'

feature 'Usage Terms' do
  let(:usage_terms_attrs) { attributes_for :usage_terms }
  let!(:usage_terms) { create :usage_terms }

  scenario 'Creating an usage terms' do
    visit usage_terms_path

    click_link 'Create Usage Terms'
    expect(current_path).to eq new_usage_term_path

    fill_in 'usage_terms[title]', with: usage_terms_attrs[:title]
    fill_in 'usage_terms[version]', with: usage_terms_attrs[:version]
    fill_in 'usage_terms[intro]', with: usage_terms_attrs[:intro]
    fill_in 'usage_terms[body]', with: usage_terms_attrs[:body]

    click_button 'Save'

    expect(current_path).to eq usage_terms_path
    expect(page).to have_css '.alert-success'
    expect(page).to have_content usage_terms_attrs[:title]
    expect(page).to have_content usage_terms_attrs[:version]
    expect(page).to have_content usage_terms_attrs[:intro]
    expect(page).to have_content usage_terms_attrs[:body]
  end

  scenario 'Destroying an usage terms' do
    visit usage_terms_path

    within "tr[data-id='#{usage_terms.id}']" do
      click_link 'Delete'
    end

    expect(current_path).to eq usage_terms_path
    expect(page).to have_css '.alert-success'
    expect(page).not_to have_content usage_terms.intro
  end
end

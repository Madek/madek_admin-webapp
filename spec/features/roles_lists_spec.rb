require 'spec_helper'
require 'spec_helper_feature'

feature 'Roles Lists' do
  scenario 'Creating' do
    visit roles_lists_path
    click_on 'Create a Roles List'
    expect(page).to have_content 'New Roles List'

    fill_in 'roles_list[labels][de]', with: 'Regisseuren Liste'
    fill_in 'roles_list[labels][en]', with: 'Directors List'
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    expect(page).to have_content 'de: Regisseuren Liste'
    expect(page).to have_content 'en: Directors List'
  end

  scenario 'Creating with empty label' do
    visit roles_lists_path
    click_on 'Create a Roles List'
    expect(page).to have_content 'New Roles List'
    click_button 'Save'

    expect(page).to have_content "Validation failed: Label can't be blank"
    expect(page).not_to have_content 'Roles List ('
  end

  scenario 'Editing' do
    roles_list = create :roles_list

    visit roles_lists_path

    filter_by_term roles_list.label

    within 'table tbody tr' do
      click_link 'Edit'
    end

    expect(page).to have_content "Edit Roles List #{roles_list}"

    new_label = Faker::Lorem.characters(number: 10)

    fill_in 'roles_list[labels][de]', with: "#{new_label} DE"
    fill_in 'roles_list[labels][en]', with: "#{new_label} EN"
    click_button 'Save'

    expect(page).to have_css '.alert-success'

    filter_by_term roles_list.label

    expect(page).not_to have_css 'table tbody tr'

    filter_by_term new_label

    within 'table tbody tr' do
      expect(page).to have_content "de: #{new_label} DE"
      expect(page).to have_content "en: #{new_label} EN"
    end
  end

  scenario 'Deleting' do
    roles_list = create :roles_list

    visit roles_lists_path

    filter_by_term roles_list.label

    within 'table tbody tr' do
      click_link 'Delete'
    end

    expect(page).to have_css '.alert-success'

    filter_by_term roles_list.label

    expect(page).not_to have_css 'table tbody tr'
  end

  def filter_by_term(term)
    fill_in 'filter[term]', with: term
    click_button 'Apply'
  end
end

require 'spec_helper'
require 'spec_helper_feature'

feature 'Roles' do
  scenario 'Creating' do
    visit roles_path

    add_role_button.click

    expect(page).to have_content 'New Role'

    fill_in 'role[labels][de]', with: 'Regisseur'
    fill_in 'role[labels][en]', with: 'Director'
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    expect(page).to have_content 'de: Regisseur'
    expect(page).to have_content 'en: Director'
  end

  scenario 'Creating with empty label' do
    visit roles_path

    add_role_button.click
    click_button 'Save'

    expect(page).to have_content "Validation failed: Label can't be blank"
    expect(page).not_to have_content 'Roles ('
  end

  scenario 'Editing' do
    role = create :role

    visit roles_path

    filter_by_term role.label

    within 'table tbody tr' do
      click_link 'Edit'
    end

    expect(page).to have_content "Edit Role #{role}"

    new_label = Faker::Lorem.characters(number: 10)

    fill_in 'role[labels][de]', with: "#{new_label} DE"
    fill_in 'role[labels][en]', with: "#{new_label} EN"
    click_button 'Save'

    expect(page).to have_css '.alert-success'

    filter_by_term role.label

    expect(page).not_to have_css 'table tbody tr'

    filter_by_term new_label

    within 'table tbody tr' do
      expect(page).to have_content "de: #{new_label} DE"
      expect(page).to have_content "en: #{new_label} EN"
    end
  end

  scenario 'Deleting' do
    role = create :role

    visit roles_path

    filter_by_term role.label

    within 'table tbody tr' do
      click_link 'Delete'
    end

    expect(page).to have_css '.alert-success'

    filter_by_term role.label

    expect(page).not_to have_css 'table tbody tr'
  end

  def add_role_button
    find_link('Create a Role')
  end

  def filter_by_term(term)
    fill_in 'filter[term]', with: term
    click_button 'Apply'
  end
end

require 'spec_helper'
require 'spec_helper_feature'

feature 'Roles' do
  let(:meta_key) { create :meta_key_roles }

  scenario 'Creating when vocabulary has no meta keys of required type' do
    vocabulary = create :vocabulary

    visit roles_path

    expect(page).to have_content 'Roles ('
    expect(add_role_button).to match_css '.disabled'

    select vocabulary.id, from: 'Vocabulary'
    click_button 'Apply'

    expect(page).to have_select 'Vocabulary', selected: vocabulary.id
    expect(add_role_button).not_to match_css '.disabled'

    add_role_button.click

    expect(page).to have_content 'New Role'

    fill_in 'role[labels][de]', with: Faker::Name.title
    click_button 'Save'

    expect(page).to have_content 'ERROR: null value in column "meta_key_id" ' \
                                 'violates not-null constraint'
  end

  scenario 'Creating' do
    vocabulary = meta_key.vocabulary

    visit roles_path

    expect(add_role_button).to match_css '.disabled'

    select vocabulary.id, from: 'Vocabulary'
    click_button 'Apply'

    expect(page).to have_select 'Vocabulary', selected: vocabulary.id
    expect(add_role_button).not_to match_css '.disabled'

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
    vocabulary = create :vocabulary

    visit roles_path

    select vocabulary.id, from: 'Vocabulary'
    click_button 'Apply'
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

    new_label = Faker::Name.title

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

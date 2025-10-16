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

  scenario 'Merging roles', browser: :firefox do
    # Create originator and receiver roles
    originator = create :role, labels: { 'de' => 'Kameramann', 'en' => 'Cameraman' }
    receiver = create :role, labels: { 'de' => 'Fotograf', 'en' => 'Photographer' }

    # Create metadata with people that use the originator role
    meta_key = create(:meta_key_people_with_roles)

    # Add our custom roles to the meta_key's roles_list
    meta_key.roles_list.roles << originator
    meta_key.roles_list.roles << receiver

    person1 = create(:person)
    person2 = create(:person)

    # Create 2 separate metadata records, each with one person having the originator role
    meta_datum1 = create(:meta_datum_people_with_roles,
                         meta_key: meta_key,
                         people_with_roles: [
                           { person: person1, role: originator }
                         ])

    meta_datum2 = create(:meta_datum_people_with_roles,
                         meta_key: meta_key,
                         people_with_roles: [
                           { person: person2, role: originator }
                         ])

    # Verify originator has 2 usages
    expect(originator.usage_count).to eq 2
    expect(receiver.usage_count).to eq 0

    # Navigate to originator role page
    visit role_path(originator)
    expect(page).to have_content 'Kameramann'

    # Click merge button
    click_link 'Merge to'

    # Accept the alert dialog
    page.driver.browser.switch_to.alert.accept

    # Now verify we're on the merge form page
    expect(page).to have_content "Merge #{originator} role to:"

    # Fill in receiver ID and submit
    fill_in 'id_receiver', with: receiver.id

    # Accept confirmation dialog and submit
    accept_confirm do
      click_button 'Merge'
    end

    # Verify originator is no longer in the roles list
    visit roles_path
    filter_by_term 'Kameramann'
    expect(page).not_to have_css 'table tbody tr'

    # Navigate to receiver page to verify it exists and has correct data
    visit role_path(receiver)
    expect(page).to have_content 'Fotograf'

    # Verify receiver has the associations in database
    receiver.reload
    expect(receiver.usage_count).to eq 2
    expect(receiver.meta_data_people.pluck(:person_id)).to match_array([person1.id, person2.id])

    # Verify originator no longer exists in database
    expect(Role.exists?(originator.id)).to be false
  end

  scenario 'Merging role to itself shows error', browser: :firefox do
    role = create :role, labels: { 'de' => 'Regisseur' }

    visit role_path(role)
    click_link 'Merge to'

    # Accept the alert dialog
    page.driver.browser.switch_to.alert.accept

    fill_in 'id_receiver', with: role.id

    # Accept confirmation dialog
    accept_confirm do
      click_button 'Merge'
    end

    expect(page).to have_css '.alert-danger, .alert-error'
    expect(page).to have_content 'The role cannot be merged to itself'
  end

  def add_role_button
    find_link('Create a Role')
  end

  def filter_by_term(term)
    fill_in 'filter[term]', with: term
    click_button 'Apply'
  end
end

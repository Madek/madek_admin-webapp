require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin People' do
  let!(:admin_user) { create :admin_user, password: 'password' }

  scenario 'Filtering persons by search term' do
    visit people_path
    fill_in 'search_term', with: 'nor'
    click_button 'Apply'
    all('table tbody tr').each do |tr|
      expect(tr).to have_content 'nor'
    end
    expect(find_field('search_term')[:value]).to eq 'nor'
  end

  scenario 'Filtering admin persons' do
    visit people_path
    check 'with_user'
    click_button 'Apply'

    within 'table tbody' do
      expect(page).to have_content admin_user.person
      expect(page).to have_content admin_user.login
    end
  end

  scenario 'Creating a new person' do
    visit people_path
    click_link 'Create person'
    expect(current_path).to eq new_person_path

    fill_in 'person[first_name]', with: 'Fritz'
    fill_in 'person[last_name]', with: 'Fischer'
    click_button 'Save'

    expect(page).to have_content 'Success! The person has been created.'
    expect(Person.find_by first_name: 'Fritz', last_name: 'Fischer').to be
  end

  scenario 'Deleting a person', browser: :firefox do
    person = create :person

    visit person_path(person)
    accept_confirm do
      click_link 'Delete'
    end

    expect(current_path).to eq people_path
    expect { person.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  scenario 'Editing a person' do
    person = create :person

    visit person_path(person)
    click_link 'Edit'
    fill_in 'person[first_name]', with: 'Fritz'
    fill_in 'person[last_name]', with: 'Fischer'
    click_button 'Save'

    expect(current_path).to eq person_path(person)
    person.reload
    expect(person.first_name).to eq 'Fritz'
    expect(person.last_name).to eq 'Fischer'
  end
end

require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin People' do
  let!(:admin_user) { create :admin_user, password: 'password' }

  scenario 'Filtering persons by search term' do
    the_search_term = 'nor'
    visit people_path
    fill_in 'filter[search_term]', with: the_search_term
    click_button 'Apply'
    all('table tbody tr').each do |tr|
      expect(tr.text.downcase).to include the_search_term.downcase
    end
    expect(find_field('filter[search_term]')[:value]).to eq 'nor'
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

  %w(PeopleGroup PeopleInstitutionalGroup Person).each do |subtype|
    scenario "Filtering people by #{subtype} subtype", browser: :firefox do
      visit people_path

      select subtype, from: 'filter[subtype]'
      click_button 'Apply'

      all('table tbody tr').each do |row|
        expect(row).to have_content subtype
      end
      expect(page).to have_select('Subtype', selected: subtype)
    end
  end

  scenario 'Showing details of a person' do
    person = create :person
    role1 = create :role
    role2 = create :role
    collection = create :collection
    create(:meta_datum_people, people: [person])
    create(:meta_datum_roles, 
           people_with_roles: [{ person: person, role: role1 },
                               { person: person, role: role2 }])
    create(:meta_datum_people, people: [person], collection: collection)
    create(:meta_datum_roles, collection: collection,
           people_with_roles: [{ person: person, role: role1 },
                               { person: person, role: role2 }])


    visit person_path(person)
    expect(page).to have_content "Used in metadata: 6 times in 2 entries and 1 collections"
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

    expect(page).to have_current_path people_path
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

  scenario 'Merging when person has no user' do
    create :person, first_name: 'foo_1'
    create :person, first_name: 'foo_2'

    visit people_path

    filter_for 'foo_'

    within 'table' do
      expect(page).to have_text 'foo_', count: 2
    end
    expect(page).not_to have_css '#merge-info'

    within 'table tbody tr:first-of-type' do
      click_link 'Merge'
    end

    expect(current_path).to eq people_path
    within '#merge-info' do
      expect(page).to have_text 'foo_'
    end

    filter_for 'foo_'

    within 'table' do
      expect(page).to have_text 'foo_', count: 1
    end

    click_link 'Merge to'

    expect(page).to have_css '.alert-success'

    filter_for 'foo_'

    expect(page).to have_text 'foo_', count: 1
    expect(page).not_to have_css '#merge-info'
  end

  scenario 'Merging when person has an user' do
    originator = create :person, first_name: 'Originator'
    receiver = create :person, first_name: 'Receiver'
    user = create :user, person: originator

    visit people_path

    filter_for 'Originator'

    within 'table tbody tr:first-of-type' do
      click_link 'Merge'
    end

    filter_for 'Receiver'

    click_link 'Merge to'

    expect(page).to have_css '.alert-success'
    expect(receiver.user).to eq user.reload

    filter_for 'Originator'

    expect(page).to have_no_text 'Originator'
  end

  scenario 'Aborting merge' do
    create :person, last_name: 'bar_1'
    create :person, last_name: 'bar_2'

    visit people_path

    filter_for 'bar_'

    within 'table tbody tr:last-of-type' do
      click_link 'Merge'
    end

    within '#merge-info' do
      click_link 'Abort'
    end

    expect(current_path).to eq people_path
    expect(page).not_to have_css '#merge-info'

    filter_for 'bar_'

    expect(page).to have_text 'bar_', count: 2
  end

  scenario 'Reseting search form during merge', browser: :firefox do
    person = create :person

    visit people_path

    within 'table tbody tr:first-of-type' do
      click_link 'Merge'
    end

    filter_for person.first_name

    expect(page).to have_css '#merge-info'

    within 'form' do
      click_link 'Reset'
    end

    expect(page).to have_css '#merge-info'
  end

  def filter_for(term)
    fill_in 'filter[search_term]', with: term
    click_button 'Apply'
  end
end

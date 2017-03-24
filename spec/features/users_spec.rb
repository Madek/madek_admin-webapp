require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Users' do
  let!(:admin_user) { create :admin_user, password: 'password' }

  scenario 'Filtering users by search term' do
    visit users_path
    fill_in 'search_term', with: 'nor'
    click_button 'Apply'
    user_rows.each do |tr|
      expect(tr).to have_content 'nor'
    end
    expect(find_field('search_term')[:value]).to eq 'nor'
  end

  scenario 'Filtering admin users' do
    visit users_path
    check 'admins_only'
    click_button 'Apply'

    within 'table tbody' do
      expect(page).to have_content admin_user.login
      expect(page).to have_content admin_user.email
    end
  end

  scenario 'Sorting users by login (default behavior)' do
    visit users_path

    expect(find_field('sort_by')[:value]).to eq('login')

    logins = user_rows.map do |tr|
      tr.find('td:first').text
    end

    expect(logins).to eq logins.sort
  end

  scenario 'Sorting users by email' do
    visit users_path

    select 'Email', from: 'sort_by'
    click_button 'Apply'
    expect(find_field('sort_by')[:value]).to eq('email')

    emails = user_rows.map do |tr|
      tr.all('td')[1].text
    end

    expect(emails).to eq emails.sort
  end

  scenario 'Sorting users by first name and last name' do
    visit users_path

    select 'First/last name', from: 'sort_by'
    click_button 'Apply'
    expect(find_field('sort_by')[:value]).to eq('first_name_last_name')

    names = user_rows.map do |tr|
      tr.all('td')[2].text
    end

    expect(names).to eq names.sort
  end

  scenario 'Creating a new user with person' do
    visit users_path
    click_link 'Create user with person'
    expect(current_path).to eq new_with_person_users_path

    fill_in 'user[person_attributes][first_name]', with: 'Fritz'
    fill_in 'user[person_attributes][last_name]', with: 'Fischer'
    fill_in 'user[login]', with: 'fritzli'
    fill_in 'user[email]', with: 'fritzli@zhdk.ch'
    fill_in 'user[password]', with: 'password'
    click_button 'Save'

    expect(page).to have_content 'Fritz Fischer'
    expect(page).to have_content 'fritzli'
    expect(page).to have_content 'fritzli@zhdk.ch'
    expect(User.find_by(login: 'fritzli')).to be
    expect(Person.find_by(first_name: 'Fritz', last_name: 'Fischer')).to be
  end

  scenario 'Creating a new user for an existing person' do
    person = create :person

    visit users_path
    click_link 'Create user for existing person'
    fill_in 'user[login]', with: 'fritzli'
    fill_in 'user[email]', with: 'fritzli@zhdk.ch'
    fill_in 'user[password]', with: 'password'
    fill_in 'user[person_id]', with: person.id
    click_button 'Save'

    expect { User.find_by!(login: 'fritzli') }.not_to raise_error
  end

  scenario 'Deleting a user', browser: :firefox do
    user = create :user

    visit user_path(user)
    accept_confirm do
      click_link 'Delete user'
    end

    expect(current_path).to eq users_path
    expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  scenario 'Editing a user' do
    user = create :user

    visit user_path(user)
    click_link 'Edit'
    fill_in 'user[login]', with: 'fritzli'
    fill_in 'user[email]', with: 'fritzli@zhdk.ch'
    click_button 'Save'

    expect(current_path).to eq user_path(user)
    user.reload
    expect(user.login).to eq 'fritzli'
    expect(user.email).to eq 'fritzli@zhdk.ch'
  end

  scenario 'Adding an user to admins' do
    user = create :user

    visit users_path
    check 'admins_only'
    click_button 'Apply'
    expect(page).not_to have_content user.email

    visit user_path(user)
    click_link 'Grant admin role'
    expect(current_path).to eq user_path(user)
    expect(find('table tr', text: 'Admin?')).to have_content 'Yes'

    visit users_path
    check 'admins_only'
    click_button 'Apply'
    expect(page).to have_content user.email
  end

  scenario 'Removing an user from admins' do
    user = create :admin_user

    visit users_path
    check 'admins_only'
    click_button 'Apply'
    expect(page).to have_content user.email

    visit user_path(user)
    click_link 'Remove admin role'
    expect(current_path).to eq user_path(user)
    expect(find('table tr', text: 'Admin?')).to have_content 'No'

    visit users_path
    check 'admins_only'
    click_button 'Apply'
    expect(page).not_to have_content user.email
  end

  scenario 'Switching to another admin user', browser: :firefox do
    user = create :admin_user

    visit users_path
    fill_in 'search_term', with: user.email
    click_button 'Apply'
    click_button 'Switch to...'
    visit root_path

    expect(page).not_to have_content 'Please log in!'
  end

  scenario 'Switching to an ordinary user' do
    user = create :user

    visit users_path
    fill_in 'search_term', with: user.email
    click_button 'Apply'
    click_button 'Switch to...'
    visit root_path

    expect(page).to have_content 'Admin access denied'
  end

  scenario 'view/show: show groups which user belongs to' do
    user = create :user
    group_1 = create(:group, name: 'foo')
    group_2 = create(:group, name: 'bar')
    user.groups << [group_1, group_2]

    visit user_path(user)

    expect(page).to have_content ': bar, foo'
    expect(page).to have_link 'bar', href: group_path(group_2)
    expect(page).to have_link 'foo', href: group_path(group_1)
  end

  def user_rows
    all('table tbody tr[data-id]')
  end
end

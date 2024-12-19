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
    check 'admins'
    click_button 'Apply'

    expect(page).to have_checked_field 'admins'
    within 'table tbody' do
      expect(page).to have_content admin_user.login
      expect(page).to have_content admin_user.email
    end
  end

  scenario 'Filtering deactivated users' do
    deactivated_user = create(:user, :deactivated)

    visit users_path
    check 'deactivated'
    click_button 'Apply'

    expect(page).to have_checked_field 'deactivated'
    within 'table tbody' do
      expect(page).to have_content "deactivated #{deactivated_user.login}"
      expect(page).to have_css(:tr, count: 1)
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

  scenario 'Reseting filters' do
    visit users_path

    fill_in 'search_term', with: 'nor'
    check 'admins'
    check 'deactivated'
    click_button 'Apply'
    click_link 'Reset'

    expect(find_field('search_term').value).to be_nil
    expect(page).to have_no_checked_field 'admins'
    expect(page).to have_no_checked_field 'deactivated'
  end

  scenario 'Creating a new user with person' do
    visit users_path
    click_link 'Create user with person'
    expect(current_path).to eq new_with_person_users_path

    fill_in 'user[first_name]', with: 'Fritz'
    fill_in 'user[last_name]', with: 'Fischer'
    fill_in 'user[login]', with: 'fritzli'
    fill_in 'user[email]', with: 'fritzli@zhdk.ch'
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
    fill_in 'user[person_id]', with: person.id
    click_button 'Save'

    expect { User.find_by!(login: 'fritzli') }.not_to raise_error
  end

  describe 'Deleting an user', browser: :firefox do
    scenario 'Is successful' do
      user = create :user

      visit user_path(user)
      accept_confirm do
        click_link 'Delete user'
      end

      expect(page).to have_current_path users_path
      expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    scenario 'Displays the correct error message if there are soft-deleted resources' do
      user = create :user
      FactoryBot.create(:collection, creator_id: user.id, deleted_at: Date.yesterday)

      visit user_path(user)
      accept_confirm do
        click_link 'Delete user'
      end

      expect(page).to have_content 'Cannot delete a user with associated soft-deleted media resources.'
      expect { user.reload }.not_to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  scenario 'Deleting an user who cannot be deleted' do
    user = create :user
    create(:collection, creator_id: user.id)

    visit user_path(user)
    click_link 'Delete user'

    expect(page).to have_content 'An error occured code: 500'
    expect(page).to have_content 'The user cannot be deleted.'
    expect(page).to have_content 'However you can mark it as deactivated.'
    expect(page).to have_link 'Click here to do that', href: edit_user_path(user)
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
    check 'admins'
    click_button 'Apply'
    expect(page).not_to have_content user.email

    visit user_path(user)
    click_link 'Grant admin role'
    expect(current_path).to eq user_path(user)
    expect(find('table tr', text: 'Admin?')).to have_content 'Yes'

    visit users_path
    check 'admins'
    click_button 'Apply'
    expect(page).to have_content user.email
  end

  scenario 'Removing an user from admins' do
    user = create :admin_user

    visit users_path
    check 'admins'
    click_button 'Apply'
    expect(page).to have_content user.email

    visit user_path(user)
    click_link 'Remove admin role'
    expect(current_path).to eq user_path(user)
    expect(find('table tr', text: 'Admin?')).to have_content 'No'

    visit users_path
    check 'admins'
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
    expect(page).to have_content 'Forbidden'
  end

  scenario 'view/show: show groups which user belongs to', browser: :firefox do
    user = create :user
    group_1 = create(:group, name: 'foo')
    group_2 = create(:group, name: 'bar')
    user.groups << [group_1, group_2]

    visit user_path(user)

    expect(page).to have_content "\nbar\nfoo"
    expect(page).to have_link 'bar', href: group_path(group_2)
    expect(page).to have_link 'foo', href: group_path(group_1)
  end

  scenario 'view/show: show deactivated label in the header' do
    deactivated_user = create(:user, :deactivated)

    visit user_path(deactivated_user)
    expect(page).to have_css '.page-header h1 span', text: 'deactivated'
  end

  scenario 'Setting user as deactivated' do
    user = create :user

    visit user_path(user)
    expect(find('tr', text: 'Active until').all('td')[1].text).not_to be_empty
    click_link 'Edit'
    fill_in("user[active_until]", with: Date.yesterday)
    click_button 'Save'

    datetime = Date.yesterday
      .to_datetime
      .change(offset: AppSetting.first.time_zone_offset)
      .end_of_day

    expect(find('tr', text: 'Active until').all('td')[1].text).to eq datetime.utc.to_s
  end

  def user_rows
    all('table tbody tr[data-id]')
  end
end

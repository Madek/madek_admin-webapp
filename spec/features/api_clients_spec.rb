require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin API Clients' do
  let!(:user) { create :user }
  let(:api_client) { create :api_client }

  scenario 'Creating a new API Client' do
    visit api_clients_path
    click_link 'Create API Client'
    expect(current_path).to eq new_api_client_path
    expect(page).not_to have_link 'Choose user'

    fill_in 'api_client[login]', with: 'test-login'
    fill_in 'api_client[description]', with: 'some description'
    click_button 'Save'

    expect(page).to have_css '.alert-info'

    fill_in 'search_term', with: user.login
    click_button 'Apply'

    within "[data-id='#{user.id}']" do
      click_link 'Assign to the API Client'
    end

    expect(current_path).to eq new_api_client_path
    expect(page).to have_field 'api_client[login]', with: 'test-login'
    expect(page).to have_field 'api_client[description]', with: 'some description'
    expect(hidden_user_id_field.value).to eq user.id
    expect(page).to have_button 'Change user'

    fill_in 'api_client[password]', with: 'securepassword'
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    expect(page).to have_content 'test-login'
    expect(page).to have_content user.user_handle

    api_client = ApiClient.find_by(login: 'test-login')
    expect(api_client).to be
    expect(api_client.password_digest).not_to be_nil

    check_session_cleanup
  end

  scenario 'Deleting an API Client', browser: :firefox do
    visit api_client_path(api_client)

    accept_confirm do
      click_link 'Delete'
    end

    expect(page).to have_css '.alert-success'
    expect(current_path).to eq api_clients_path
    expect { api_client.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  scenario 'Editing an API Client without changing password', browser: :firefox do
    visit api_client_path(api_client)
    expect(page).to have_css('[data-attr="password_digest"]')
    password_digest = get_value(:password_digest)
    click_link 'Edit'
    expect(page).to have_field 'Login', with: api_client.login
    expect(hidden_user_id_field.value).to eq api_client.user.id
    expect(find_field('New password').value).to be_blank
    fill_in 'api_client[description]', with: 'test description'
    click_button 'Save'
    expect(page).to have_css '.alert-success'
    api_client.reload
    expect(current_path).to eq api_client_path(api_client)
    expect(api_client.description).to eq 'test description'
    #binding.pry
    expect(api_client.password_digest.presence).to eq password_digest.presence
  end

  scenario 'Changing responsible user', browser: :firefox do
    visit api_client_path(api_client)
    click_link 'Edit'
    previous_user_id = hidden_user_id_field.value
    previous_login = get_value_of_input('login')
    previous_description = get_value_of_input('description')
    fill_in 'api_client[login]', with: 'new_login'
    fill_in 'api_client[description]', with: 'new description'
    click_button 'Change user'

    expect(page).to have_css '.alert-info'

    fill_in 'search_term', with: user.login
    click_button 'Apply'

    expect(page).to have_css '.alert-info'

    within "[data-id='#{user.id}']" do
      click_link 'Assign to the API Client'
    end

    expect(current_path).to eq edit_api_client_path(api_client)
    expect(hidden_user_id_field.value).to eq user.id
    expect(hidden_user_id_field.value).not_to eq previous_user_id
    expect(get_value_of_input('login')).not_to eq previous_login
    expect(get_value_of_input('description')).not_to eq previous_description

    click_button 'Save'

    expect(page).to have_css '.alert-success'
    expect(page).to have_content user.to_s

    check_session_cleanup
  end

  scenario 'Reseting password' do
    visit api_client_path(api_client)

    password_digest = get_value(:password_digest)
    click_link 'Edit'
    fill_in 'New password', with: 'newsecurepassword'
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    api_client.reload
    expect(api_client.password_digest).not_to eq password_digest
  end

  scenario 'Editing permission descriptions' do
    visit api_client_path(api_client)
    click_link 'Edit'

    fill_in 'api_client[permission_descriptions][de]', with: 'Berechtigungen DE'
    fill_in 'api_client[permission_descriptions][en]', with: 'Permissions EN'
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    api_client.reload
    expect(api_client.permission_description(:de)).to eq 'Berechtigungen DE'
    expect(api_client.permission_description(:en)).to eq 'Permissions EN'
  end

  def get_value(attr)
    find("[data-attr='#{attr}'] td:last-child").text
  end

  def get_value_of_input(name)
    find_field("api_client[#{name}]").value
  end

  def hidden_user_id_field
    find('[name="api_client[user_id]"]', visible: false)
  end

  def check_session_cleanup
    visit users_path
    expect(page).not_to have_css '.alert-info'
  end
end

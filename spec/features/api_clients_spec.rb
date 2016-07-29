require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Api Clients' do
  let!(:user) { create :user }
  let(:api_client) { create :api_client }

  scenario 'Creating a new API Client' do
    visit api_clients_path
    click_link 'Create API Client'
    expect(current_path).to eq new_api_client_path

    fill_in 'api_client[login]', with: 'test-login'
    fill_in 'api_client[password]', with: 'securepassword'
    select "#{user.person} [#{user.login}]", from: 'api_client[user_id]'
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    expect(page).to have_content 'test-login'
    expect(page).to have_content user.person.to_s

    api_client = ApiClient.find_by(login: 'test-login')
    expect(api_client).to be
    expect(api_client.password_digest).not_to be_empty
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

  scenario 'Editing an API Client without changing password' do
    user_select_value = "#{api_client.user.person} [#{api_client.user.login}]"

    visit api_client_path(api_client)
    expect(page).to have_css('[data-attr="password_digest"]')
    password_digest = get_value(:password_digest)
    click_link 'Edit'
    expect(page).to have_field 'Login', with: api_client.login
    expect(page).to have_select 'User', selected: user_select_value
    expect(find_field('New password').value).to be_blank
    fill_in 'api_client[description]', with: 'test description'
    click_button 'Save'

    expect(page).to have_css '.alert-success'
    api_client.reload
    expect(current_path).to eq api_client_path(api_client)
    expect(api_client.description).to eq 'test description'
    expect(api_client.password_digest).to eq password_digest
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

  def get_value(attr)
    find("[data-attr='#{attr}'] td:last-child").text
  end
end

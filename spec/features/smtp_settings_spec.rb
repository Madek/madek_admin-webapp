require 'spec_helper'
require 'spec_helper_feature'

def make_current_user_beta_tester_notifications!
  uid = find("#current-user")['data-id']
  gid = Madek::Constants::BETA_TESTERS_NOTIFICATIONS_GROUP_ID.to_s
  User.find(uid).groups << Group.find(gid)
end

feature 'SMTP Settings' do
  scenario 'Updating works', browser: :firefox do
    visit root_path
    expect(page).not_to have_content('SMTP')
    make_current_user_beta_tester_notifications!
    visit root_path
    click_on('SMTP')
    click_on('Edit')
    check('smtp_settings[is_enabled]')
    fill_in('smtp_settings[domain]', with: 'domain')
    click_on('Save')
    expect(find('tr', text: 'is_enabled').all('td')[1].text).to eq 'true'
    expect(find('tr', text: 'domain').all('td')[1].text).to eq 'domain'
  end
end

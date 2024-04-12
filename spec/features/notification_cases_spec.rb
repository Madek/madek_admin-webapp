require 'spec_helper'
require 'spec_helper_feature'

def make_current_user_beta_tester_notifications!
  uid = find("#current-user")['data-id']
  gid = Madek::Constants::BETA_TESTERS_NOTIFICATIONS_GROUP_ID.to_s
  User.find(uid).groups << Group.find(gid)
end

feature 'Notification Cases' do
  scenario 'Updating works' do
    visit root_path
    expect(page).not_to have_content('Notifications')
    make_current_user_beta_tester_notifications!
    visit root_path
    click_on('Notifications')

    notif_tmpl = NotificationCase.find('transfer_responsibility')

    find('tr', text: notif_tmpl.id).click_on('Edit')
    fill_in('notification_case[description]', with: 'new description')
    click_on('Save')
    expect(find('tr', text: 'description').all('td')[1].text).to eq 'new description'
  end
end

require 'spec_helper'
require 'spec_helper_feature'

def make_current_user_beta_tester_notifications!
  uid = find("#current-user")['data-id']
  gid = Madek::Constants::BETA_TESTERS_NOTIFICATIONS_GROUP_ID.to_s
  User.find(uid).groups << Group.find(gid)
end

feature 'Notification Templates' do
  scenario 'Updating works' do
    visit root_path
    expect(page).not_to have_content('Notifications')
    make_current_user_beta_tester_notifications!
    visit root_path
    click_on('Notifications')

    notif_tmpl = NotificationTemplate.find('transfer_responsibility')
    notif_tmpl_old = notif_tmpl.dup

    find('tr', text: notif_tmpl.id).click_on('Edit')
    fill_in('notification_template[description]', with: 'new description')
    NotificationTemplate::CATEGORIES.each do |tmpl_cat|
      [:en, :de].each do |lang|
        fill_in("notification_template[#{tmpl_cat}][#{lang}]",
                with: "#{notif_tmpl.send(tmpl_cat)[lang]} foo bar")
      end
    end
    click_on('Save')
    expect(find('tr', text: 'description').all('td')[1].text).to eq 'new description'

    notif_tmpl.reload

    NotificationTemplate::CATEGORIES.each do |tmpl_cat|
      [:en, :de].each do |lang|
        expect(notif_tmpl.send(tmpl_cat)[lang]).to eq "#{notif_tmpl_old.send(tmpl_cat)[lang]} foo bar"
      end
    end
  end

  context 'Validation works' do
    scenario 'Liquid syntax error' do
      visit root_path
      expect(page).not_to have_content('Notifications')
      make_current_user_beta_tester_notifications!
      visit root_path
      click_on('Notifications')
      find('tr', text: 'transfer_responsibility').click_on('Edit')
      fill_in('notification_template[description]', with: 'new description')
      fill_in("notification_template[ui][en]", with: "en: ui template {{ foo }")
      click_on('Save')
      expect(page.text).to match(/code: 500.*Liquid syntax error/m)
    end

    scenario 'Undefined variable error' do
      visit root_path
      expect(page).not_to have_content('Notifications')
      make_current_user_beta_tester_notifications!
      visit root_path
      click_on('Notifications')
      find('tr', text: 'transfer_responsibility').click_on('Edit')
      fill_in('notification_template[description]', with: 'new description')
      fill_in("notification_template[ui][en]", with: "en: ui template {{ foo }}")
      click_on('Save')
      expect(page.text).to match(/code: 500.*Liquid error.*undefined variable/m)
    end
  end
end

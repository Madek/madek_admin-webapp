require 'spec_helper'
require 'spec_helper_feature'

feature 'Session' do
  describe 'Flash notification if session expiring soon' do
    scenario 'red' do
      visit '/admin'
      AuthSystem.all.update(session_max_lifetime_hours: 0.1)
      visit '/admin'
      find('.alert.alert-danger',
           text: 'Error! You will be logged out in less than 10 minutes. Save your input and log in again.')
    end

    scenario 'orange' do
      visit '/admin'
      AuthSystem.all.update(session_max_lifetime_hours: 0.3)
      visit '/admin'
      find('.alert.alert-warning',
           text: 'Warning! You will be logged out in less than 30 minutes. Save your input and log in again.')
    end
  end
end

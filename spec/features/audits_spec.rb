require 'spec_helper'
require 'spec_helper_feature'

feature 'Audits' do

  before(:each) do
    flush_audits
  end

  scenario "GET: no audits", browser: :firefox do
    visit '/admin/test/audits/test1'
    expect(page).to have_content 'OK'
    expect(AuditedRequest.count).to eq 0
    expect(AuditedResponse.count).to eq 0
    expect(AuditedChange.count).to eq 0
  end

  scenario "POST: audits", browser: :firefox do
    visit '/admin/test/audits/test1'
    click_button 'Submit to test2'
    expect(page).to have_content 'Submit OK'
    expect(AuditedRequest.count).to eq 1
    expect(AuditedResponse.count).to eq 1
    expect(AuditedResponse.first.status).to be >= 200
    expect(AuditedChange.count).to eq 1
  end

  scenario "POST: raise Exception", browser: :firefox do
    Capybara.raise_server_errors == false

    visit '/admin/test/audits/test1'
    click_button 'Submit to test3'
    expect(page).to have_content /something went wrong/i
    expect(AuditedRequest.count).to eq 1
    expect(AuditedResponse.count).to eq 1
    expect(AuditedResponse.first.status).to eq 500
    expect(AuditedChange.count).to eq 0

    Capybara.raise_server_errors == true
  end
end

def flush_audits
  AuditedRequest.delete_all
  AuditedResponse.delete_all
  AuditedChange.delete_all
end

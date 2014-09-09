require 'spec_helper'
require_relative '../../app/helpers/session'

include SessionHelpers

feature 'User signs out' do

	before(:each) do
		User.create!(:email => "test@test.com",
					:password => 'test',
					:password_confirmation => 'test')
	end

	scenario 'while being signed in' do
		sign_in('test@test.com', 'test')
		click_button "sign out"
		expect(page).to have_content("Good bye!")
		expect(page).not_to have_content("welcome, test@test.com")
	end

end
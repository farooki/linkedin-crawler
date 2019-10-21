class MasterLookup < ApplicationRecord
  def self.login(browser, email, password)
    browser.text_field(:name,'session_key').set(email)
    sleep(1)
    browser.text_field(:name,'session_password').set(password)
    sleep(1)
    browser.button(:class, 'sign-in-form__submit-btn').click
    sleep(10)
  end

  def self.load_google_driver(headless = true)
    Selenium::WebDriver::Chrome::Service.driver_path = "#{Rails.root.to_s}/plugins/mac/chromedriver"
    browser = Watir::Browser.new :chrome, headless: headless
    browser
  end

end

require 'nokogiri'
require 'open-uri'

class JobPost < ApplicationRecord
  TARGET_URL = 'https://www.linkedin.com/jobs/search/?currentJobId=1557604264&f_I=4%2C6%2C43%2C96&f_LF=f_EA&f_PP=100495523&f_TPR=r2592000&geoId=101165590&keywords=architect&location=United%20Kingdom&sortBy=R'

  def self.crawl_jobs_from_link(url)
    browser = MasterLookup.load_google_driver(false)
    browser.goto 'https://www.linkedin.com/'
    MasterLookup.login(browser, '', '')
    browser.goto JobPost::TARGET_URL
    sleep(5)
    html = browser.html
    doc = Nokogiri::HTML(html)
    browser.div('data-control-name': 'A_jobssearch_job_result_click')
  end

  def self.scrap_and_save_jobs(browser)

    for i in 0..40
      number = i == 0 ? 1 : (i * 25)
      url = "https://www.linkedin.com/jobs/search/?f_I=4%2C6%2C43%2C96&f_LF=f_EA&f_PP=100495523&f_TPR=r2592000&geoId=101165590&keywords=architect&location=United%20Kingdom&sortBy=R&start=#{number}"
      browser.goto url
      sleep(3)
      jobs = []
      browser.lis(:class, 'occludable-update').each do |job|
        job.imgs(:class, 'job-card-search__logo-image').first.click
        sleep(1)
        html = browser.html
        doc = Nokogiri::HTML(html)
        inner_job = job.html
        inner_doc = Nokogiri::HTML(inner_job)
        inner_doc.css('h3 a span').first.destroy rescue nil

        jobs << {
            :job_title => (inner_doc.css('h3 a').text.gsub('Promoted','').strip rescue nil),
            :job_url => (inner_doc.css('a').map{|j| (j['href'] if j['href'].include?('/jobs/view/') rescue nil)}.compact.first rescue "#{rand(9999999)}" ),
            :compay_name => (inner_doc.css('h4 a').text.strip rescue nil),
            :location => (inner_doc.css('h4').first.next_element.text.strip rescue nil),
            :posted_date => (inner_doc.css('time').first.text.strip rescue nil),
            :views => (doc.css('span.jobs-details-top-card__bullet span.a11y-text').first.parent.text.gsub('Number of views','').strip rescue ''),
            :applicants => (doc.css('.jobs-details-job-summary__text--ellipsis').map{|a| a.text if a.text.include?('applicants')}.compact.first rescue ''),
            :employees => (doc.css('.jobs-details-job-summary__text--ellipsis').map{|a| a.text if a.text.include?('employe')}.compact.first rescue ''),
            :company_category => (doc.css('.jobs-details-job-summary__text--ellipsis').map{|a| a if a.text.include?('employe')}.compact.first.parent.next_element.text.strip rescue ''),
            :job_description => (doc.css('article.jobs-description__container').first.text.tr("\n","").strip rescue ''),
            :posted_by_name => '',
            :posted_by_title => '',
            :about_us_company => (doc.css('div#company-description-text').first.text.strip rescue ''),
            :page_id => i
        }
      end

      insert_able_data = []
      jobs.each do |job|
        insert_able_data << {
            title: job[:job_title],
            company: job[:compay_name],
            url: job[:job_url],
            settings: job,
            created_at: Time.now,
            updated_at: Time.now
        }
      end
      JobPost.insert_all(insert_able_data)
    end
  end
end

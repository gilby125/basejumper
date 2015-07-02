require 'capybara'
require 'capybara-webkit'
require 'net/http'
require 'open-uri'
require 'pry'

require_relative './metro_codes.rb'
require_relative './pososhok_parser.rb'



class PososhokQuery2

  include Capybara::DSL

  def run(opts)
   # page.driver.allow_url('www.pososhok.ru')

    # NOTE: MUST USE METRO CODES, NOT AIRPORTS (IAH -> HOU)
    if AIRPORT_TO_METRO.has_key? opts[:src]
      puts "Warning: Replacing #{opts[:src]} with #{AIRPORT_TO_METRO[opts[:src]]}"
      opts[:src] = AIRPORT_TO_METRO[opts[:src]]
    end

    if AIRPORT_TO_METRO.has_key? opts[:dst]
      puts "Warning: Replacing #{opts[:dst]} with #{AIRPORT_TO_METRO[opts[:dst]]}"
      opts[:dst] = AIRPORT_TO_METRO[opts[:dst]]
    end

    if opts[:src] == opts[:dst]
      puts "Warning: identical source and destination"
      return []
    end

    Capybara.current_driver = :webkit   #_debug

    Capybara.ignore_hidden_elements = false
    Capybara.match = :first
    Capybara.default_wait_time = 30
    #Capybara.current_session.driver.browser.set_proxy host: 'localhost', port: 8123
    Capybara.current_session.reset!
    #browser = Capybara.current_session.driver.browser
    page.driver.block_unknown_urls
    page.driver.allow_url("stat1.pososhok.ru")
    page.driver.allow_url("prev.pososhok.ru")
    page.driver.allow_url("stat2.pososhok.ru")

    page.driver.allow_url("www.google-analytics.com")
    page.driver.allow_url("cleversite.ru")
    page.driver.allow_url("counter.yadro.ru")
    page.driver.allow_url("www.google-analytics.com")

    page.driver.allow_url("mc.yandex.ru")

    #target = 'http://old.pososhok.ru/partner/english/'
    #target1 = 'http://www.pososhok.ru/partner/english'
    target = 'http://prev.pososhok.ru/?redesign-force=true'
    # target = 'https://prev.pososhok.ru/partner/english/'
    # puts "Visiting #{target}..."
    #visit target1
    visit target






    puts "Filling in locations..."
    fill_in 'FlightSearchForm.departureLocation_0', with: opts[:src]
    fill_in 'FlightSearchForm.arrivalLocation_0', with: opts[:dst]

    find(:xpath, '//input[@name="FlightSearchForm.departureLocation.0.CODE"]').set opts[:src]
    find(:xpath, '//input[@name="FlightSearchForm.arrivalLocation.0.CODE"]').set opts[:dst]
    find(:xpath, '//input[@name="FlightSearchForm.searchType"]').set "TARIFFS"

    puts "Starting search..."
    click_on 'search-button'

    puts "Checking URL..."
    while URI.parse(current_url).query.nil?
     # puts current_url
     # sleep(1)
    end

    # BAD: http://www.pososhok.ru/partner/english/avia/?err=1&arrivalLocation.0=EGS
    # GOOD: http://www.pososhok.ru/partner/english/avia/step2_tariffs.html?action=select_tariff
    # We've found an error...
    if URI.parse(current_url).query.include? "err"
      puts "ERROR: Invalid airport in search"
      return []
    end

    #puts "Good URL #{current_url}..."

    begin
      find(:xpath, '//div[@id="search-results"]')
        # Sometimes the search just spins forever
        # Try YTO - GKA
    rescue Capybara::ElementNotFound
      save_screenshot "error.png"
      puts "ERROR: No results found!"
      return []
    end


    return PososhokParser::parse(page.html)
    save_and_open_page
  end

end
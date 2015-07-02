require 'date'
require 'pry'
require './pososhok_query.rb'
require './pososhok_query2.rb'
require  './pososhok_parser.rb'
require 'net/http'
require 'uri'
require 'mongo_mapper'

MongoMapper.database = "Basefare"


class Routeresults
  include MongoMapper::Document

  key :dte, Date
  key :departure, String
  key :destination, String
  key :routekey, String
  key :priceusd, Integer
  key :farebase, String
end


SRC = "HOU"


def get_filename(src)
  return "valid_#{src}"
end

# Get all airports
f = File.read('openflights/openflights/data/airports.dat')
airports = f.scan(/"([A-Z0-9]{3})"/).map { |a| a.first.strip }
# p airports

# Remove all known-valid from the list so we don't retry them
known_valid = []
File.readlines(get_filename(SRC)).each { |l| known_valid << l.strip } if File.exists? get_filename(SRC)
puts "Found #{known_valid.length} known valid airports"
# p known_valid

# Optional: Ignore everything from airports up to the index of the last known-valid airport
puts "Ignoring airports up to index #{airports.index(known_valid.last)}"
airports = airports[airports.index(known_valid.last)..-1] unless airports.index(known_valid.last).nil?

# Subtract known-valid airports
(airports - known_valid).each_with_index do |a,i|
  flydate = Date.today+30
  opts = {
    src: SRC,
    dst: a,
    date: flydate
  }
  puts "Querying #{opts}"

  prices = PososhokQuery2.new.run(opts)


  sleep(300)
  # Check that search was correct
  unless prices.empty?

    if opts[:src] != prices.first[:src]
      puts "IGNORING: Requested source #{opts[:src]} doesn't match returned source #{prices.first[:src]}"
    elsif opts[:dst] != prices.first[:dst]
      p opts[:dst]
      p prices.first[:dst]

            puts "IGNORING: Requested destination #{opts[:dst]} doesn't match returned destination #{prices.first[:dst]}"
    else
      puts prices



     # open('Fares.json', 'a') { |e|
      #  e.puts  prices.to_json
     # }

      f = File.open(get_filename(opts[:src]), 'a')
      f.puts a
      f.close

      sleep(30)
      citypair = Routeresults.create({:fares=> prices, :dte=>flydate,:departure=>SRC,:destination=>a,:routekey=>SRC + a})
      citypair.save


  end
end
   puts "Sleeping after airport #{i+1} of #{airports.length}..."

 #sleep(1)


end

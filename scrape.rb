require 'date'
require 'pry'
require_relative './dates.rb'
require_relative './pososhok_query.rb'
require_relative './pososhok_query2.rb'
require_relative './pososhok_parser.rb'
#require_relative './openflights/openflights/data'
require 'net/http'
require 'uri'
require 'mongo_mapper'
require 'pg'
require 'sequel'
require 'orchestrate'



MongoMapper.database = "Basefare"

DB = Sequel.connect('postgres://user:password@127.0.0.1:5432/DBNAME')

results = DB[:results]


client = Orchestrate::Client.new('xxxx-xxxx-xxxxx-xxxx-xxxxxxxx') # Orchestrate.io api key goes here(not needed)
response = client.ping


class Routeresults
  include MongoMapper::Document

  key :dte, Date
  key :departure, String
  key :destination, String
  key :routekey, String
  key :lowprice, Integer
  key :lowestairline, String
  key :routekey, String
  key :fares, String




end

SRC = ARGV[0]

def get_filename(src)
  return "valid_#{src}"
end

# Get all airports
f = File.read('./basejumper/openflights/openflights/data/main_routes.dat') # change path if needed
airports = f.scan(/"([A-Z0-9]{3})"/).map { |a| a.first.strip }
# p airports


known_valid = []
File.readlines(get_filename(SRC)).each  { |l| known_valid << l.strip } if File.exists? get_filename(SRC)
puts "Found #{known_valid.length} known valid airports"
 p known_valid

#Optional: Ignore everything from airports up to the index of the last known-valid airport
puts "Ignoring airports up to index #{airports.index(known_valid.last)}"
airports = airports[airports.index(known_valid.last)..-1] unless airports.index(known_valid.last).nil?

# Subtract known-valid airports
airports.each_with_index do |a,i|
#(airports - known_valid).each_with_index do |a,i|
  flydate = $departure_date
  opts = {
      src: SRC,
      dst: a,
      date: flydate
  }
  puts "Querying #{opts}"

  prices = PososhokQuery2.new.run(opts)
#.to_json
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



      f = File.open(get_filename(opts[:src]), 'a')
      f.puts a
      f.close
      airline1 = prices.map { |x| x[:airline] }
      farecode = prices.map { |x| x[:fare_basis] }.first
      usd = prices.map { |x| x[:price] }
      lowestfare= usd.min.to_i do |a, b|

      end
    end
    #puts airline1.first
    #puts lowestfare
    #  puts lowestairline
    #puts farecode

    sleep(10)
    r = client.post(:Routeresults,  {'fares_array' => prices})


    #r = client.post(:Routeresults,  {prices => farecode})
    #r = client.post(:Routeresults, 'airfare', {prices => farecode})
    #r = client.put(:Routeresults, 'airfare', {'prices' => 'price'})
    citypair = Routeresults.create({
      :fares => prices,
      :lowprice => lowestfare,
      :dte => flydate,
      :departure => SRC,
      :destination => a,
      :routekey => SRC + a})
    citypair.save
    results.insert(:base_fare=>lowestfare,:dte =>flydate, :lowprice=>lowestfare, :departure=>SRC,  :destination=>a, :routekey=>SRC + a,\
    :modified=>Time.now,  :lowestairline=>airline1.first,:fare_code=>farecode)
     #puts(r.location)

     #g = client.get(:Routeresults, 'fares_array')
     #puts(g.body)
  end
end

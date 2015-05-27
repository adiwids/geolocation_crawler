require 'openssl'
require 'geokit'
require 'yaml'

keys = YAML.load_file("#{File.dirname(__FILE__)}/api_key.yml")
##
#  Geokit Configuration
#
   Geokit::default_units = :meters
   Geokit::Geocoders::request_timeout = 3
   Geokit::Geocoders::provider_order = [:google]
   Geokit::Geocoders::secure = false
   Geokit::Geocoders::GoogleGeocoder.client_id = keys['GOOGLE_NATIVE_CLIENT_ID'].first
   #Geokit::Geocoders::GoogleGeocoder.cryptographic_key = keys['GOOGLE_NATIVE_CLIENT_SECRET'].first
   Geokit::Geocoders::GoogleGeocoder.api_key = keys['GOOGLE_PUBLIC_SERVER_API_KEY'].first
#
##

class Node
  attr_accessor :longitude, :latitude, :label, :id

  def initialize label=nil
    unless label.nil?
      @label = label
      begin
        puts "[DEBUG] label: #{@label}"
        geocode = Geokit::Geocoders::GoogleGeocoder.geocode(@label)
        @longitude = geocode.lng
        @latitude = geocode.lat
      rescue Geokit::Geocoders::GeocodeError => e
        puts "[ERROR] #{e.inspect}"
      end
    end
  end

  def lat_long
    "#{@latitude}, #{@longitude}".strip
  end

  def valid?
    (!@label.nil? && @label != "") && ensure_longitude_valid && ensure_latitude_valid
  end

  def self.find(id)
    sql = "SELECT nodes.id, nodes.label, nodes.longitude, nodes.latitude
           FROM nodes
           WHERE nodes.id = '#{id}'
           LIMIT 0, 1"

    begin
      db = SQLite3::Database.open "data.db"
      statement = db.prepare sql
      rows = statement.execute

      node = self.new
      rows.each do |r|
        node.id = r[0]
        node.label = r[1]
        node.longitude = r[2]
        node.latitude = r[3]
      end

      return node

    rescue Exception => e
      puts "[ERROR] Connect database failed."
    ensure
      db.close if db
    end
  end

  def self.find_by_label(label)
    sql = "SELECT nodes.id, nodes.label, nodes.longitude, nodes.latitude
           FROM nodes
           WHERE nodes.label = '#{label}'
           LIMIT 0, 1"

    begin
      db = SQLite3::Database.open "data.db"
      statement = db.prepare sql
      rows = statement.execute

      node = self.new
      rows.each do |r|
        node.id = r[0]
        node.label = r[1]
        node.longitude = r[2]
        node.latitude = r[3]
      end

      return node

    rescue Exception => e
      puts "[ERROR] Connect database failed."
    ensure
      db.close if db
    end
  end

  def self.search keyword
    return []
  end

  def save
    return false
  end

  private
    def ensure_longitude_valid
      @longitude > -180.0 && @longitude < 180.0
    end

    def ensure_latitude_valid
      @latitude > -90.0 && @latitude < 90.0
    end
end

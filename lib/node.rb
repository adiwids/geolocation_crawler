require 'sqlite3'
require 'openssl'
require 'geokit'
require 'yaml'
require 'net/http'
require 'uri'

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
  DATABASE_PATH = "#{File.dirname(__FILE__)}/data.db"

  attr_accessor :longitude, :latitude, :label, :id, :file_store

  def initialize label=nil
    unless label.nil?
      @label = label
      begin
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
           LIMIT 0, 1;"

    begin
      db = SQLite3::Database.open DATABASE_PATH
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
      puts e
    ensure
      db.close if db
    end
  end

  def self.find_by_label(label)
    sql = "SELECT nodes.id, nodes.label, nodes.longitude, nodes.latitude
           FROM nodes
           WHERE nodes.label = '#{label}'
           LIMIT 0, 1;"

    begin
      db = SQLite3::Database.open DATABASE_PATH
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
    end
  end

  def self.search keyword
    sql = "SELECT nodes.* FROM nodes WHERE LOWER(nodes.label) LIKE '%#{keyword.downcase}%';"
    begin
      db = SQLite3::Database.open DATABASE_PATH
      statement = db.prepare sql
      rows = statement.execute

      nodes = []
      rows.each do |r|
        node = self.new

        node.id = r[0]
        node.label = r[1]
        node.longitude = r[2]
        node.latitude = r[3]

        nodes << node
      end

      return nodes

    rescue Exception => e
      puts "[ERROR] Connect database failed."
    end
  end

  def save node=nil
    exists = Node.search_location @longitude, @latitude

    is_saved = false

    if exists
      is_saved = update(node)
    else
      is_saved = create(node)
    end

    return is_saved
  end

  def self.search_location lng, lat
    sql = "SELECT nodes.id, nodes.label, nodes.longitude, nodes.latitude
           FROM nodes
           WHERE nodes.longitude=#{lng} AND nodes.latitude=#{lat} LIMIT 0,1;"
    begin
      db = SQLite3::Database.open DATABASE_PATH
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
    end
  end

  def self.fetch_geocoder_result formatted_address, save_to_file=false
    map_api_path = "http://maps.googleapis.com/maps/api/geocode/json"
    param = "address=#{URI.encode(formatted_address)}"

    path = [map_api_path, param].join("?")
    path_uri = URI.parse(path)

    http = Net::HTTP.new(path_uri.host, path_uri.port)
    response = http.request(Net::HTTP::Get.new(path_uri.request_uri))

    if save_to_file
      filename = "#{formatted_address.gsub(' ', '_')}".gsub(',', '-')
      self.save_to_json("./results", filename, response.body)
    end

    response.body
  end

  def self.save_to_json path, filename, content=""
    file = File.join(path, "#{filename}.json")
    unless File.exists?(file)
      begin
        f = File.new(file, 'w')
        f.write(content)
        f.close
      rescue Exception => e
        puts "Failed to write '#{file.to_s}', #{e.message}"
      end
    else
      begin
        f = File.open(file, 'w')
        f.write(content)
        f.close
      rescue Exception => e
        puts "Failed to overwrite '#{file.to_s}', #{e.message}"
      end
    end
  end

  private
    def ensure_longitude_valid
      @longitude > -180.0 && @longitude < 180.0
    end

    def ensure_latitude_valid
      @latitude > -90.0 && @latitude < 90.0
    end

    def create node=self
      sql = "INSERT INTO nodes(id, label, longitude, latitude)
             VALUES(#{generate_id}, '#{node.label}', #{node.longitude}, #{node.latitude})"
      begin
        db = SQLite3::Database.open DATABASE_PATH
        statement = db.prepare sql

        if statement.execute
          return true
        else
          return false
        end

      rescue Exception => e
        puts "[ERROR] Connect database failed."
      end
    end

    def update node=self
      sql = "UPDATE nodes SET
                nodes.label='#{node.label}',
                nodes.longitude=#{node.longitude},
                nodes.latitude=#{node.latitude}
              WHERE nodes.id=#{node.id};"
      begin
        db = SQLite3::Database.open DATABASE_PATH
        statement = db.prepare sql

        if statement.execute
          return true
        else
          return false
        end

      rescue Exception => e
        puts "[ERROR] Connect database failed."
      end
    end

    def generate_id
      sql = "SELECT nodes.id FROM nodes ORDER BY nodes.id DESC;"
      begin
        db = SQLite3::Database.open DATABASE_PATH
        statement = db.prepare sql
        rows = statement.execute

        node = self.new
        rows.each do |r|
          node.id = r[0]
        end

        return node.id

      rescue Exception => e
        puts "[ERROR] Connect database failed."
      end
    end
end

require 'spec_helper'
require 'node'

RSpec.describe Node do
  let(:subject) { Node.new }

  before do
    subject.longitude = 0.0
    subject.latitude = 0.0
  end
  
  it "should create new instance" do
    expect(subject).to be_instance_of(Node)
  end

  describe "#lat_long" do
    it "should return latitude and longitude values" do
      lat_long = "#{subject.longitude}, #{subject.latitude}".strip
      expect(subject.lat_long).to eq(lat_long)
    end
  end
end

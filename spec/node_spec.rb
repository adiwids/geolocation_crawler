require 'spec_helper'
require 'node'

RSpec.describe Node do
  let(:subject) { Node.new }

  before do
    subject.label = "Sample Node"
    subject.longitude = 0.0
    subject.latitude = 0.0
  end

  it "should create new instance" do
    expect(subject).to be_instance_of(Node)
  end

  context "when label attribute is set as object parameter" do
    before do
      @node = Node.new("Jalan Cassa, Sukajadi, Kota Bandung, Jawa Barat 40164, Republic of Indonesia")
    end

    it "should create new instance with label" do
      expect(@node).to be_instance_of(Node)
      expect(@node.label).to eql("Jalan Cassa, Sukajadi, Kota Bandung, Jawa Barat 40164, Republic of Indonesia")
    end

    xit "should set longitude and latitude value via Geokit::Geocoders::GoogleGeocoder" do
      expected = Geokit::Geocoders::GoogleGeocoder.geocode(@node.label)

      expect(@node.latitude).to eq(expected.lat)
      expect(@node.longitude).to eq(expected.lng)
    end
  end

  describe "#lat_long" do
    it "should return latitude and longitude values" do
      lat_long = "#{subject.longitude}, #{subject.latitude}".strip
      expect(subject.lat_long).to eq(lat_long)
    end
  end

  describe "#valid?" do
    context "when node attributes values are valid" do
      it "should return true" do
        expect(subject.valid?).to eql(true)
      end
    end

    context "when node has no label" do
      it "should return false" do
        subject.label = ""
        expect(subject.valid?).to eql(false)
      end
    end

    context "when longitude or latitude out of range" do
      it "should return false" do
        subject.longitude = 200.0
        expect(subject.valid?).to eql(false)

        subject.latitude = -100.0
        expect(subject.valid?).to eql(false)
      end
    end
  end

  describe ".find" do
    before do
      @label = "Sample Node"
      @node = double('Node')
      @node.stub(:id).with(1)
      Node.stub(:find).with(1).and_return(@node)
    end

    it "should respond with label text parameter" do
      allow(Node).to receive(:find).with(1)
      Node.find_by_label(1)
    end

    it "should return one object as result" do
      expect( Node.find(1) ).to eql(@node)
    end
  end

  describe ".find_by_label" do
    before do
      @label = "Sample Node"
      @node = double('Node')
      @node.stub(:label).with(@label)
      Node.stub(:find_by_label).with(@label).and_return(@node)
    end

    it "should respond with label text parameter" do
      allow(Node).to receive(:find_by_label).with(@label)
      Node.find_by_label(@label)
    end

    it "should return one object as result" do
      expect( Node.find_by_label(@label) ).to eql(@node)
    end
  end

  describe ".search" do
    before do
      @keyword = "Node"
      @nodes = %w[node1 node2 node3].each_with_index do |n, i|
          node = Node.new
          node.label = n
          node.longitude = 0.0 + i
          node.latitude = 0.0 + i

          node
        end
      Node.stub(:search).with(@keyword).and_return(@nodes)
    end

    it "should respond with keyword text parameter" do
      allow(Node).to receive(:search).with(@keyword)
      Node.search(@keyword)
    end

    it "should return objects collection as array" do
      stubbed_search_result = @nodes
      expect(Node.search(@keyword)).to eql(stubbed_search_result)
    end
  end

  describe "#save" do
    before do
      subject.label = "Change Label to This"
      Node.stub(:find_by_label).with("Change Label to This").and_return(subject)
    end

    context "when node is invalid" do
      it "should not allowed to save" do
        subject.label = ""
        expect(subject.save).to eql(false)
      end
    end

    context "when longitude and latitude values exists" do
      it "should update changed attribute only" do
        #
        # Update Node.label from "Sample Node" to "Change Label to This"
        subject.label = "Change Label to This"
        expect(subject.save).to eql(true)
	      #
        node = Node.find_by_label("Change Label to This")
        #
        # Node.label should not be similar as before
        expect(node.label).not_to eql("Sample Node")

        # Rest unchanged attributes should be similar as before
        expect(node.latitude).to eql(subject.latitude)
        expect(node.longitude).to eql(subject.longitude)
      end
    end

    context "when longitude and latitude is a new location" do
      it "should create a record"
    end
  end
end

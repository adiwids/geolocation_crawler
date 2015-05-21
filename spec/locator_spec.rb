require 'spec_helper'
require 'locator'

RSpec.describe Locator do
  it "should create new instance" do
    expect(Locator.new).to be_instance_of(Locator)
  end  
end

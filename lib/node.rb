class Node
  attr_accessor :longitude, :latitude

  def lat_long
    "#{@latitude}, #{@longitude}".strip
  end
end

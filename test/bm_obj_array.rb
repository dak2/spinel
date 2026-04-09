class Point
  attr_accessor :x
  attr_accessor :y
  def initialize(x, y)
    @tag = "p"
    @x = x
    @y = y
  end
  def to_s
    x.to_s + "," + y.to_s
  end
end

points = [Point.new(1, 2), Point.new(3, 4), Point.new(5, 6)]
points.each { |p|
  puts p.to_s
}
puts points.length

# push to obj array
more = []
more.push(Point.new(10, 20))
more.push(Point.new(30, 40))
more.each { |p|
  puts p.x + p.y
}

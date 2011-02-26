class Item < Struct.new(:text, :inner, :outer, :distance, :level, :info)
	def initialize(params={})
		params.each do |key, value|
			send("#{key}=", value)
		end
	end
	
  def full_distance
    i = (self.inner == nil) ? 1 : self.inner
    o = (self.outer == nil) ? 1 : self.outer
    self.distance * i * o
  end
end

class Parser
  def self.parseSchedule(full)
    tItems = full.split "\n"
    items = tItems.map{|i| parseItem(i.chomp)}
    {:full_distance => full_schedule_distance(items), :items => items.length}
  end
  
  def self.parseItem(text)
    re = /^#{LEVEL}#{MULTI}#{MULTI}#{DIST}/i
    parse = re.match text
    item = Item.new(:full_text => text)
    case parse[1].length
    when 0
      item.level = 0
      item.outer = parse[3].to_i unless parse[3].nil?
      item.inner = parse[6].to_i unless parse[6].nil?
    when 1,2
      item.level = 1
      item.outer = nil
      item.inner = parse[3].to_i unless parse[3].nil?
    when 3,4
      item.level = 2
      item.outer = nil
      item.inner = nil
    end
    item.distance = parse[8].to_i unless parse[8].nil?
    return item
  end
  
  def self.full_schedule_distance(items)
    distance = 0
    last_outer = 1
    last_inner = 1
    for item in items
      if item.level == 0
        distance += item.full_distance
        last_outer = 1
        last_inner = 1
      elsif item.level == 1
        distance += item.full_distance * last_outer
        last_inner = 1
      elsif item.level == 2
        distance += item.full_distance * last_outer * last_inner
      end
      last_outer = item.outer unless (item.outer == nil)
      last_inner = item.inner unless (item.inner == nil)
    end
    return distance
  end
  
private
  MULTI = '((\d{1,2})(\*|x))?'
  DIST = '(\d+)($|\s|m$|m\s|m,\s)'
  LEVEL = '(\s{0,4})'
end

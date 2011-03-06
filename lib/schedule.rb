class Schedule
  def self.attrs
    [ :slug, :body, :tags, :items, :full_distance, :created_at]
  end

  def attrs
    self.class.attrs.inject({}) do |a, key|
      a[key] = send(key)
      a
    end
  end

  attr_accessor *attrs

  def created_at=(t)
    @created_at = t.is_a?(Time) ? t : Time.parse(t)
  end

  def initialize(params={})
    params.each do |key, value|
      send("#{key}=", value)
    end
  end

#################

  def self.new_from_slugs(slugs)
    return [] if slugs.empty?
    ids = slugs.map { |slug| db_key_for_slug(slug) }
    ids.map {|id| new Redis::Value.new(id, :marshal => true).value }
  end

  def self.find_by_slug(slug)
    new Redis::Value.new(db_key_for_slug(slug), :marshal => true).value
  end

  def self.find_tagged(tag)
    list = Redis::List.new("#{self}:tagged:#{tag}")
    new_from_slugs list.values
  end

  def self.find_range(start, len, by_rank=false)
    if by_rank
      slugs = Redis::SortedSet.new(ranked_key).revrange(start,len)
    else
      slugs = Redis::List.new(chrono_key)[start,len].reverse
    end
    new_from_slugs slugs
  end
  
  def self.get_tags
    Redis::Set.new("#{self}:tags").members.map{|t| [t , Redis::Counter.new("#{self}:tagcount:#{t}").value]}
  end

  def self.uprank(slug)
    Redis::SortedSet.new(ranked_key).incr(slug)
  end
  

#################

  def self.all_by_rank
    find_range(0,9999,true)
  end

  def self.all
    find_range(0,9999)
  end

  def self.create(params)
    params[:tags] = chop_crap(params[:tags])
    schedule = new(params.merge(Parser.parseSchedule(params[:body])))
    schedule.body.gsub!(/\r\n/,"\r") 
    schedule.save
    schedule.build_indexes
    schedule
  end

  def update(new_body, new_tags)
    tmp = Parser.parseSchedule(new_body)
    self.body = new_body.gsub(/\r\n/,"\r")
    self.full_distance = tmp[:full_distance]
    self.items = tmp[:items]

    at = self.tags.split
    self.tags = self.class.chop_crap(new_tags)
    nt = self.tags.split

    (nt-at).each {|tag| add_tag(tag)}
    (at-nt).each {|tag| rem_tag(tag)}

    self.save
  end

#################

  def save
    obj = Redis::Value.new(db_key, :marshal => true)
    obj.value = attrs
  end
  
  def build_indexes
    Redis::SortedSet.new(self.class.ranked_key)[slug] = 0
    Redis::List.new(self.class.chrono_key) << slug

    tags.split.each do |tag|
      add_tag(tag)
    end
  end

  def add_tag(tag)
    Redis::Counter.new("#{self.class}:tagcount:#{tag}").increment do
      Redis::List.new("#{self.class}:tagged:#{tag}") << slug
      Redis::Set.new("#{self.class}:tags") << tag
    end
  end

  def rem_tag(tag)
    Redis::Counter.new("#{self.class}:tagcount:#{tag}").decrement do |val|
      if val == 0
        Redis::Set.new("#{self.class}:tags").delete tag
        Redis::List.new("#{self.class}:tagged:#{tag}").del
      else
        Redis::List.new("#{self.class}:tagged:#{tag}").delete slug
      end
    end
  end

#################

  def self.make_slug(body, created_at)
    # TODO
    body.hash.abs
  end
  
  def url
    "/#{slug}"
  end
  
  def linked_tags
    tags.split.inject([]) do |accum, tag|
      accum << "<a href=\"/tags/#{tag}\">#{tag}</a>"
    end.join(" ")
  end
  
  def self.chop_crap(value)
    value.scan(/\w+|,|\./).delete_if{|t| t =~ /,|\./}.map{|t| t.downcase.strip}.join(' ')
  end

  def score
    Redis::SortedSet.new(self.class.ranked_key)[slug]
  end

  def self.db_key_for_slug(slug)
    "#{self}:slug:#{slug}"
  end
  
  def db_key
    self.class.db_key_for_slug(slug)
  end

  def self.ranked_key
    "#{self}:ranked"
  end
  def self.chrono_key
    "#{self}:chrono"
  end

end

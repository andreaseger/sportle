require 'json'

class Schedule
	def self.attrs
		[ :slug, :body, :tags, :items, :full_distance ]
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

	class RecordNotFound < RuntimeError; end

#################

	def self.new_from_json(json)
		raise RecordNotFound unless json
		new JSON.parse(json)
	end

	def self.new_from_slugs(slugs)
		return [] if slugs.empty?
		ids = slugs.map { |slug| db_key_for_slug(slug) }
		DB.mget(*ids).map { |json| new_from_json(json) }
	end

	def self.find_by_slug(slug)
		new_from_json DB[db_key_for_slug(slug)]
	end

	def self.find_tagged(tag)
		new_from_slugs DB.lrange("#{App.db_base_key}:tagged:#{tag}", 0, 99999)
	end

	def self.find_range(start, len, by_rank=false)
	  if by_rank
	    new_from_slugs DB.zrevrange(ranked_key, start, start + len - 1)
	  else
		  new_from_slugs DB.lrange(chrono_key, start, start + len - 1)
		end
	end
	
#################

  def self.all_by_rank
    find_range(0,9999,true)
  end

  def self.all
    find_range(0,9999)
  end

  def self.create(params)
    params[:tags] = safe_split(params[:tags]).join
		schedule = new(params.merge(Parser.parseSchedule(params[:body])))
		schedule.save
		schedule.create_indexes
		schedule
  end

  def save
    DB[db_key] = attrs.to_json
  end

  def create_indexes
    DB.zadd(self.class.ranked_key, 0, slug)
    DB.lpush(self.class.chrono_key, slug)

		tags.split.each do |tag|
			DB.lpush("#{App.db_base_key}:tagged:#{tag}", slug)
			DB.sadd "#{App.db_base_key}:tags", tag
		end
  end
  
  def self.get_tags
    DB.smembers "#{App.db_base_key}:tags"
  end

#################

	def self.make_slug(body)
	  # TODO
    body.hash.abs
	end

  def self.db_key_for_slug(slug)
    "#{App.db_base_key}:slug:#{slug}"
  end
  
	def db_key
		self.class.db_key_for_slug(slug)
	end

  def self.ranked_key
    "#{App.db_base_key}:ranked"
  end
  def self.chrono_key
    "#{App.db_base_key}:chrono"
  end
  
##################
  
  def url
    "/s/#{slug}/"
  end
  
	def linked_tags
		tags.split.inject([]) do |accum, tag|
			accum << "<a href=\"/s/tags/#{tag}\">#{tag}</a>"
		end.join(" ")
	end
	
	def self.safe_split(value)
    value.scan(/\w+|,|\./).delete_if{|t| t =~ /,|\./}
  end
end

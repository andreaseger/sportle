require 'json'

class Schedule
	def self.attrs
		[ :slug, :body, :tags, :items ]
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


#################

  def self.all
    new_from_slugs(DB.zrange("#{App.db_base_key}:sorted", 0, -1))
  end

  def self.create(params)
		schedule = new(params)
		schedule.save
		schedule.create_indexes
		schedule
  end

  def save
    DB[db_key] = attrs.to_json
  end

  def create_indexes
    DB.zadd("#{App.db_base_key}:ranked", 0, slug)
    DB.lpush("#{App.db_base_key}:chrono", slug)

		tags.split.each do |tag|
			DB.lpush("#{App.db_base_key}:tagged:#{tag}", slug)
		end
  end

#################

	def self.make_slug(body)
	  # TODO
    body.hash
	end

  def self.db_key_for_slug(slug)
    "#{App.db_base_key}:slug:#{slug}"
  end
  
	def db_key
		self.class.db_key_for_slug(slug)
	end

##################
  
  def url
    "/s/#{slug}/"
  end
end

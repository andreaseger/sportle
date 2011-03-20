class RedisClass
  def self.attrs
    []
  end

  def attrs
    self.class.attrs.inject({}) do |a, key|
      a[key] = send(key)
      a
    end
  end

  attr_accessor *attrs

  def initialize(params={})
    params.each do |key, value|
      send("#{key}=", value)
    end
  end

  def self.build(params)
    new params
  end

  def self.create(params)
    obj = build(params)
    obj.save
    obj
  end

  def save
    obj = Redis::Value.new(db_key, :marshal => true)
    obj.value = attrs
  end

  def db_key
    raise NotImplementedError
  end
end
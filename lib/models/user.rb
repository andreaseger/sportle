class User < RedisClass
  def self.attrs
    [ :id, :email, :name ]
  end

  def self.db_key_for_id(id)
    "#{self}:#{id}"
  end
  
  def db_key
    self.class.db_key_for_id(id)
  end

  def self.find_by_id(id)
    if u = Redis::Value.new(db_key_for_id(id),:marshal => true)
      new  u
    else
      nil
    end
  end
end

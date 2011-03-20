class Auth < RedisClass
  def self.attrs
    [ :provider, :uid ]
  end

  def self.db_key_for_provider_uid(provider,uid)
    "#{self}:#{provider}:#{uid}"
  end
  
  def db_key
    self.class.db_key_for_provider_uid(provider,uid)
  end

  def self.find_by_provider_and_uid(provider,uid)
    if u = Redis::Value.new(db_key_for_provider_uid(provider,uid),:marshal => true)
      new  u
    else
      nil
    end
  end
end
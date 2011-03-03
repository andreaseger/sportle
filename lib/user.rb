class User < Struct.new(:provider, :uid, :name)
  def initialize(params={})
    send("provider=",params["provider"])
    send("uid=",params["uid"])
    send("name=",params["user_info"]["name"])
  end
  def self.find_by_provider_and_uid(provider,uid)
    if u = Redis::Value.new("#{self}:#{provider}:#{uid}",:marshal => true)
      new  u
    else
      nil
    end
  end
  def self.find_by_key(user_key)
    tmp=user_key.split(':')
    find_by_provider_and_uid(tmp[0],tmp[1])
  end
  def key
    "#{self.provider}:#{self.uid}"
  end
end

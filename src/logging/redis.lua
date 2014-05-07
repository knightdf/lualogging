--saves logging information in redis
--
----------------------------------------------------------------------

local logging = require "logging"
local redis = require "redis"
conn = nil 

local openRedisLogger = function (redis_ip, redis_port)
    if not conn then 
	conn = redis.connect(redis_ip, redis_port)
    end
    return conn 
end

function logging.redis(redis_ip, redis_port, logPattern)
    if not redis_ip or not redis_port or type(redis_ip) ~= "string" or type(redis_port) ~= "number" then 
	redis_ip = "127.0.0.1"
	redis_port = 6379
    end

    return logging.new( function(self, level, message)
	local conn = openRedisLogger(redis_ip, redis_port)
	if not conn then 
	    return nil
	end
	local s = logging.prepareLogMsg(logPattern, os.date(), level, message)
	--get channel from message(split by '%channel% ' and get the first match)
	local a, b, channel = s:find("%%(.+)%%")
	local s = s:sub(1,a-1) .. s:sub(b+1)
	if type(channel) ~= "string" or channel == " " or channel == "" then
	    channel = "logging"
	end
	conn:publish(channel, s)
	return true
    end)
end

return logging.redis

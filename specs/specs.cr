
require "../src/da_redis"
require "inspect_bang"

# This is a place holder.
# I will write better tests later on.

DA_Redis.port 6380

DA_Redis.connect { |conn|
  puts conn.send("PING")
  puts conn.send("GET", "my_media.c99.title")
  puts conn.send("SET", "my_temp.value", "abc", "EX", 5.to_s)
  puts conn.send("SET", "my_temp.date", Time.now.to_s, "EX", 5.to_s)
  puts conn.send("GET", "my_temp.value")
  puts conn.send("ECHO", "hello world")
  puts conn.keys("my_temp.*")
}

DA_Redis.connect { |redis|
  puts redis.keys("my_temp.*")
  keys = redis.keys("my_temp.*")
  puts redis.send("DEL", keys)
  puts redis.send("DEL", [] of String)
}



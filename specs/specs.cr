
require "../src/da_redis"

# This is a place holder.
# I will write better tests later on.

port = 6380
conn = DA_Redis.new(port)
puts conn.send("PING")
puts conn.send("GET", "my_media.c99.title")
puts conn.send("SET", "my_temp.value", "abc", "EX", 5.to_s)
puts conn.send("SET", "my_temp.date", Time.now.to_s, "EX", 5.to_s)
puts conn.send("GET", "my_temp.value")
puts conn.send("ECHO", "hello world")
puts conn.keys("my_temp.*")
conn.close

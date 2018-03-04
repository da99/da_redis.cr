
require "../src/da_redis"
require "da_spec"
require "inspect_bang"

extend DA_SPEC

DA_Redis.port 6380

describe "send" do
  it "receives PONG when sending PING" do
    actual = nil
    DA_Redis.connect { |conn| actual = conn.send("PING") }
    assert actual == "PONG"
  end # === it "works"

  it "sets a value with SET" do
    actual = nil
    expected = "Abc#{Time.now.epoch}"
    DA_Redis.connect { |conn|
      conn.send("SET", "my_temp.value", expected, "EX", 5.to_s)
      actual = conn.send("GET", "my_temp.value")
    }
    assert actual == expected
  end # === it "sets a value with SET"

  it "can ECHO" do
    actual = DA_Redis.connect { |conn|
      conn.send("ECHO", "hello world")
    }
    assert actual == "hello world"
  end # === it "can ECHO"

  it "can DEL keys" do
    actual = DA_Redis.connect { |r|
      r.send("SET", "my_temp_DEL_keys.1", "a", "EX", 1.to_s)
      r.send("SET", "my_temp_DEL_keys.2", "a", "EX", 1.to_s)
      r.send("DEL", "my_temp_DEL_keys.1")
      r.send("DEL", "my_temp_DEL_keys.2")
      r.keys("my_temp_DEL_keys.*")
    }
    assert actual == %w[]
  end # === it "can DEL keys"
end # === desc "send"

describe ".keys" do
  it "retrieves keys when the wildcard is used: *" do
    actual = DA_Redis.connect { |r|
      r.send("SET", "my_temp_keys.1", "a", "EX", 1.to_s)
      r.send("SET", "my_temp_keys.2", "a", "EX", 1.to_s)
      r.keys("my_temp_keys.*")
    }
    assert actual == %w[my_temp_keys.1 my_temp_keys.2]
  end # === it "retrieves keys when the wildcard is used: *"
end # === desc ".keys"



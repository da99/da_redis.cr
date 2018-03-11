
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

describe ".send lists" do
  it "can LPUSH a value" do
    actual = [] of String
    DA_Redis.connect { |r|
      r.send("LPUSH", "my_temp_list", "1")
      r.send("LPUSH", "my_temp_list", "2")
      r.send("LPUSH", "my_temp_list", "3")
      actual.push r.send("RPOP", "my_temp_list").to_s
      actual.push r.send("RPOP", "my_temp_list").to_s
      actual.push r.send("RPOP", "my_temp_list").to_s
    }
    assert actual == %w[1 2 3]
  end # === it "can LPUSH a valie"

  it "can RPUSH a value" do
    actual = [] of String
    DA_Redis.connect { |r|
      r.send("RPUSH", "my_temp_list", "1")
      r.send("RPUSH", "my_temp_list", "2")
      r.send("RPUSH", "my_temp_list", "3")
      actual.push r.send("RPOP", "my_temp_list").to_s
      actual.push r.send("RPOP", "my_temp_list").to_s
      actual.push r.send("RPOP", "my_temp_list").to_s
    }
    assert actual == %w[3 2 1]
  end # === it "can RPUSH a value"

  it "can push/pop strings with whitespace" do
    actual = [] of String
    DA_Redis.connect { |r|
      r.send("RPUSH", "my_temp_list", "i am")
      r.send("RPUSH", "my_temp_list", "happy today")
      r.send("RPUSH", "my_temp_list", "because it is Friday")
      actual.push r.send("RPOP", "my_temp_list").to_s
      actual.push r.send("RPOP", "my_temp_list").to_s
      actual.push r.send("RPOP", "my_temp_list").to_s
    }
    assert actual == ["because it is Friday", "happy today", "i am"]
  end # === it "can push/pop strings"
end # === desc ".send lists"

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

describe ".send LLEN" do
  it "retrieves an Int32" do
    actual = DA_Redis.connect { |r|
      r.send("LPUSH", "my_temp_list.1", "1")
      r.send("LPUSH", "my_temp_list.1", "2")
      r.send("LLEN", "my_temp_list.1")
    }
    assert actual == 2
  end # === it "retrieves an Int32"
end # === desc ".send LLEN"



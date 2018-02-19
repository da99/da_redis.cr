

require "socket"

class DA_Redis

  # =============================================================================
  # Class
  # =============================================================================

  alias REDIS_VALUE = String | Int64 | Nil
  alias ARRAY = Array(REDIS_VALUE)

  @@CONNECTIONS = [] of TCPSocket

  def self.close
    @@CONNECTIONS.each { |x|
      x.close
    }
  end

  def self.receive_and_parse(conn)
    type = conn.read_char
    line = begin
             raw_line = conn.gets(chomp: false)
             if !raw_line
               raise Exception.new("Disconnected")
             end
             raw_line.byte_slice(0, raw_line.bytesize - 2)
           end

    # === From: https://redis.io/topics/protocol
    case type
    when '-' # Error
      raise Exception.new(line.inspect)

    when ':' # Integer
      line.to_i64

    when '*' # Array
      arr = [] of String | Int64 | Nil
      size = line.to_i64
      size.times { |i|
        result = receive_and_parse(conn)
        case result
        when REDIS_VALUE
          arr << result
        else
          raise Exception.new("Can't store this value in a Redia Array: #{result.inspect}")
        end
      }
      arr

    when '$' # Bulk string
      length = line.to_i

      # The "Null bulk string" aka nil
      return nil if length == -1
      return "" if length == 0

      str = String.new(length) do |buffer|
        conn.read_fully(Slice.new(buffer, length))
        {length, 0}
      end

      # Ignore \r\n
      conn.skip(2)
      str

    when '+'
      # Simple string
      line

    else
      raise Exception.new("Unknown Redis type: #{type}: #{line.inspect}")
    end
  end

  # =============================================================================
  # Instance
  # =============================================================================

  getter port : Int32
  @is_connected = false
  getter socket : TCPSocket

  def initialize(@port)
    @socket = TCPSocket.new("localhost", @port)
    @socket.sync = false
    @is_connected = true
    @@CONNECTIONS.push @socket
  end # === def initialize

  def connected?
    @is_connected
  end # === def connected?

  def read_char
    @socket.read_char
  end

  def gets(**names)
    @socket.gets(**names)
  end

  def read_fully(*args)
    @socket.read_fully(*args)
  end

  def skip(*args)
    @socket.skip(*args)
  end

  def send(*message)
    @socket << "*" << message.size << "\r\n"
    message.each do |element|
      case element
      when String
        @socket << "$" << element.bytesize << "\r\n" << element << "\r\n"
      else
        raise Exception.new("Invalid value: #{element.inspect} in message: #{message.inspect}")
      end
    end
    @socket.flush

    self.class.receive_and_parse(self)
  end # def send

  def keys(pattern : String)
    arr = [] of String
    result = send("KEYS", pattern)
    case result
    when ARRAY
      result.each { |x|
        case x
        when String
          arr << x
        else
          raise Exception.new("Unknown value for KEYS #{pattern.inspect}: #{x.inspect}")
        end
      }
    end
    arr
  end # === def keys

  def close
    if connected?
      @socket.close
      @is_connected = false
    end
  end

end # === class Conn


at_exit {
  DA_Redis.close
}


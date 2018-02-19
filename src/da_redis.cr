

require "socket"

class DA_Redis

  # =============================================================================
  # Class
  # =============================================================================

  @@CONNECTIONS = [] of TCPSocket

  def self.close
    @@CONNECTIONS.each { |x|
      x.close
    }
  end

  # =============================================================================
  # Instance
  # =============================================================================

  getter port : Int32
  @is_connected = false
  @socket : TCPSocket

  def initialize(@port)
    @socket = TCPSocket.new("localhost", @port)
    @socket.sync = false
    @is_connected = true
    @@CONNECTIONS.push @socket
  end # === def initialize

  def connected?
    @is_connected
  end # === def connected?

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

    type = @socket.read_char

    line = begin
             raw_line = @socket.gets(chomp: false)
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

    when '$' # Bulk string
      length = line.to_i

      # The "Null bulk string" aka nil
      return nil if length == -1
      return "" if length == 0

      str = String.new(length) do |buffer|
        @socket.read_fully(Slice.new(buffer, length))
        {length, 0}
      end

      # Ignore \r\n
      @socket.skip(2)
      str.inspect

    when '+'
      # Simple string
      line

    else
      raise Exception.new("Cannot parse response with type #{type}: #{line.inspect}")
    end
  end

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


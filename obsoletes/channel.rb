require "socket"
require "json"

class Channel
  def initialize sock_data
  end

  def start
  end

  def stop
  end
end

class UDPSocketChannel < Channel
  PORT=11185
  def initialize(port=PORT)
    @port = port
  end

  def request msg
    data = ""
    udp = UDPSocket.open()
    p "udp"
    udp.connect("10.10.10.10", @port)
    p "connect"
    udp.send(JSON.dump(msg)+"\n", 0)
    data = udp.recvfrom(65535)[0]
    p data
    udp.close
    return JSON.parse(data)
  rescue => e
    p e
    return {:error => "json failed"}
  end

  def register_recv_handler recv_handler
    @recv_handler = recv_handler
  end

  def start
    @th = Thread.new do
      Socket.udp_server_loop(PORT) do |msg, src|
        req_msg = JSON.parse(msg)
        begin
          resp_msg = @recv_handler.call(req_msg)
        rescue
          resp_msg = @recv_handler.call(error_request(data))
        ensure
          src.reply(JSON.dump(resp_msg)+"\n")
        end
      end
    end
  end

  def stop
    @th.kill
  end

  private
  def error_request data
    return { "coommand" => "error", "data" => data }
  end

end

class UnixSocketChannel < Channel
  SOCKPATH="/var/run/lighthouse.sock"

  def initialize sock_path=SOCKPATH
    @sock_path = sock_path || SOCKPATH
    @th = nil
  end

  def request msg
    data = ""
    p @sock_path
    UNIXSocket.open(@sock_path) do |sock|
      sock.write(JSON.dump(msg)+"\n")
      data = sock.gets
    end
    return JSON.parse(data)
  rescue => e
    p e
    return {:error => "json failed"}
  end

  def register_recv_handler recv_handler
    @recv_handler = recv_handler
  end

  # expected json is
  # {"command": "XXXX", ....}
  def start
    @th = Thread.new do
      Socket.unix_server_loop(@sock_path) do |sock, addr|
        data = sock.gets
        req_msg = JSON.parse(data)
        begin
          resp_msg = @recv_handler.call(req_msg)
        rescue
          resp_msg = @recv_handler.call(error_request(data))
        ensure
          sock.write(JSON.dump(resp_msg)+"\n")
        end
      end
    end
  end

  def stop
    @th.kill
  end

  private
  def error_request data
    return { "coommand" => "error", "data" => data }
  end
end

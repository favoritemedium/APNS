module APNS
  class Feedback
    def self.feedback_connection
      raise "The path to your pem file is not set. (APNS.pem = /path/to/cert.pem)" unless APNS::Config.pem
      raise "The path to your pem file does not exist!" unless File.exist?(APNS::Config.pem)

      context      = OpenSSL::SSL::SSLContext.new
      context.cert = OpenSSL::X509::Certificate.new(File.read(APNS::Config.pem))
      context.key  = OpenSSL::PKey::RSA.new(File.read(APNS::Config.pem), APNS::Config.pass)

      fhost        = APNS::Config.host.gsub!('gateway', 'feedback')
      puts fhost

      sock = TCPSocket.new(fhost, 2196)
      ssl  = OpenSSL::SSL::SSLSocket.new(sock, context)
      ssl.connect

      return sock, ssl
    end

    def self.feedback
      sock, ssl = self.feedback_connection

      apns_feedback = []

      while line = sock.gets # Read lines from the socket
        line.strip!
        f = line.unpack('N1n1H140')
        apns_feedback << [Time.at(f[0]), f[2]]
      end

      ssl.close
      sock.close

      return apns_feedback
    end
  end
end
require "./cryload/*"
require "http"
require "colorize"
require "option_parser"

module Cryload
  class LoadGenerator
    def initialize(@host, @number)
      @stats = Stats.new @number
      ch = generate_request_channel
      loop do
        check_log
        ch.receive
      end
    end

    def generate_request_channel()
      channel = Channel(Nil).new
      uri = URI.parse @host
      client = HTTP::Client.new uri.host.not_nil!, port: uri.port, ssl: uri.scheme == "https"
      spawn do
        loop do
          start_time = Time.now
          response = client.get uri.full_path
          end_time = Time.now
          request = Request.new start_time, end_time, response.status_code
          @stats.requests << request
          channel.send nil
        end
      end
      channel
    end

    def check_log
      Logger.new @stats
    end
  end
end
options = {} of Symbol => String
options[:requests] = "1000"
OptionParser.parse(ARGV) do |opts|
  opts.banner = "Usage: ./cryload [options]"

  opts.on("-s SERVER", "--server SERVER", "Target Server") do |v|
    options[:server] = v
  end

  opts.on("-n NUMBERS", "--numbers NUMBERS", "Number of requests to make") do |v|
    options[:numbers] = v
  end

  opts.on("-h", "--help", "Print Help") do |v|
    puts opts
  end

  if ARGV.empty?
    puts opts
  end

end.parse!

if options.has_key?(:server) && options.has_key?(:numbers)
  puts "Preparing to make it CRY for #{options[:numbers]} requests!".colorize(:green)
  Cryload::LoadGenerator.new options[:server], options[:numbers].to_i
elsif options.has_key?(:server)
  puts "You have to specify '-n' or '--numbers' flag to indicate the number of requests to make".colorize(:red)
elsif options.has_key?(:numbers)
  puts "You have to specify '-s' or '--server' flag to indicate the target server".colorize(:red)
else
  puts "You have to specify '-n' and '-s' flags, for help use '-h'".colorize(:red)
end

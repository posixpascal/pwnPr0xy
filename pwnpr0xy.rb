require_relative 'lib/proxyrb'
require 'bundler/setup'
require 'colorize'
require 'logger'
require 'ipaddr'
require 'yaml'
require 'net/ping'


class PwnProxy
	include ProxyRB
	attr_accessor :ip, :logger, :proxies, :networks

	def initialize(log_output = STDOUT)
		@ip = IP.new()
		@logger = Logger.new(log_output)
		@logger.formatter = proc do |severity, datetime, progname, msg|
			msg = "#{severity.bold}: #{msg}\n"
			if severity == "INFO"
				msg.light_blue
			elsif severity == "WARN"
				msg.yellow
			else
				msg.green
			end
		end
	end

	def process(yaml)
		@proxies = yaml["proxies"]
		@networks = yaml["networks"]
		@logger.info("Found #{@proxies.size} proxy configuration(s)")
		@logger.info("Found #{@networks.size} proxy configuration(s)")

		self.process_networks()
		@logger.info("Networks processed. Starting monitoring mode")
		
		@thread = Thread.new { self.monitor_networks() }
		@thread.join
	end

	def monitor_networks()
		#debug: return Proxy.from_pwn @networks.last, @proxies

		while true
			# let's loop over our network configurations
			valid = false
			@current_network = nil
			@networks.each do |network|
				if network.is_valid?
					valid = true
					@logger.info "I'm currently in #{network.name.bold}"
					@current_network = network
					break
				end
			end
			if valid == false
				if @default
					@logger.warn "Couldn't find a suitable network. Gonna switch to `default`"
					@current_network = @default
				else
					@logger.warn "Couldn't find any suitable network."
					@logger.warn "No `default`  configuration found. I'll just wait a few secs and try again. :)"
				end
			end

			if @current_network
				@logger.info "Adapting proxy changes for #{@current_network.name} in a second..."
		

				Proxy.from_pwn(@current_network, @proxies)
				exit
			end

			sleep 80
		end
	end

	def parse_detectors(detectors)
		classes = []
		detectors.each do |key, value|
			classes << [key.capitalize, value]
		end

		classes.map do |klass|
			Object.const_get("#{klass[0]}Rule").new(klass[1])
		end
	end

	def process_networks()
		@logger.debug("Checking network configurations...")
		res = []
		@networks.each do |network|
			network_name = network[0]
			network_rule = network[1]
			if network_name == "default"
				@default = Network.new(network_name, network_rule, [])
			end
			network_detectors = parse_detectors(network_rule["detect_by"]) unless network_rule["detect_by"].nil?
			network_detectors ||= []
			logger.debug "Found #{network_detectors.size} detector(s) for #{network_name}"

			res << Network.new(network_name, network_rule, network_detectors)
		end
		@networks = res
	end
end


# PwnProxy rules
class Rule < PwnProxy
	def initialize(data)
		super()
	end

	def detect
		return false
	end
end

class PingRule < Rule
	def initialize(data)
		super(data)
		@ips = data
	end

	def detect
		@ips.each do |ip|
			@logger.debug("Pinging #{ip}")
			
			if Net::Ping::External.new(ip).ping?
				@logger.info "#{ip} responds to PING!"
				return true
				break
			end
		end
		return false
	end
end

class TimeRule < Rule
	def initialize(data)
		super(data)
		@time = data.map do |time|
			eval(time)
		end
	end

	def detect
		@time.each do |time|
			@logger.debug("Checking if current Time is in time range: #{time}")
			if time.cover? Time.now
				return true
			end
		end
		return false
	end
end

class IprangeRule < Rule
	def initialize(data)
		super(data)
		# data is an array of ips
		@ipranges = data
	end
	def detect
		@ipranges.each do |iprange|
			@logger.debug("Checking if current IP is in ip range #{iprange}...")
			net = IPAddr.new(iprange)
			if net === @ip.v4.ip_address
				return true
				break
			end
		end
		return false
	end
end

class Network < PwnProxy
	attr_accessor :name, :proxy, :rule
	def initialize(name, rule, detectors)
		super()
		@name = name
		@rule = rule
		@detectors = detectors
		@proxy = rule["proxy"] || nil
	end

	def is_valid?
		valid = @detectors.map(&:detect).flatten
		return valid.length == 1 && valid[0] == true
	end
end

pwn = PwnProxy.new()
pwn.logger.debug("PWNProxy initialized")
pwn.logger.info("IP: #{pwn.ip.v4 ? pwn.ip.v4.ip_address : "offline mode."}")
pwn.logger.debug("Reading proxyrb.yml")
pwn.process(YAML.load open('proxyrb.yml'))
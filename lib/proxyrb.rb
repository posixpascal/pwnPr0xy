require 'socket'

module ProxyRB
	class IP
		attr_accessor :v4
		def initialize
			@v4 = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
		end
	end

	class Proxy
		attr_accessor :host, :port, :username, :password, :protocols
		def initialize(data)
			@host = data[:host]
			@port = data[:port]
			@username = data[:username]
			@password = data[:password]
		end

		def self.from_pwn(data, proxies)
			proxy = proxies[data.rule["proxy"]]
			if proxy
				if proxy["auth"].nil?
					proxy["auth"] = {
						:username => nil,
						:password => nil
					}
				end
				return Proxy.new({:host => proxy["host"],
				:port => proxy["port"],
				:username => proxy["auth"]["username"],
				:password => proxy["auth"]["password"]}).set({
					:firefox => proxy["firefox"],
					:git => proxy["git"],
					:env => proxy["env"],
					:systemwide => proxy["systemwide"]
					})
			else
				puts "No proxy configuration was passed. Resetting..."
				Proxy.new({}).set(nil)
			end
		end
		def proxy_url
			p = ""
			if @username and @username.length and @password and @password.length
				p += @username + ":" + @password + "@"
			end
			if @host
				p += @host
			end
			if @port 
				p += ":#{@port}"
			end
			return p
		end

		def set(data)
			if data.nil?
				`git config --global http.proxy ""`
				`git config --global https.proxy ""`
				set_env!(nil)
				set_firefox!(nil)
				set_systemwide!(nil)
				puts "Unset HTTP proxy"
				return
			end
			puts "Setting http://#{self.proxy_url()} as proxy..."
			if data[:git]
				set_git!
				
			end

			if data[:firefox]
				set_firefox!
			end

			if data[:env]
				set_env!
			end

			if data[:systemwide]
				set_systemwide!
			end

		end

		protected
		def set_git!
			`git config --global http.proxy "#{proxy_url}"`
			`git config --global https.proxy "#{proxy_url}"`
				puts "Done setting git proxy."
		end

		def set_firefox!(reset=false)
			# macosx only implementation
			path = "#{ENV['HOME']}/Library/Application\ Support/Firefox/Profiles/"
			config = Dir["#{path}*.default/prefs.js"][0]
			data = open(config, "r").read()
			unless reset
				data.gsub!(/user_pref\(\"network.proxy.http(.+)\)\;/, "")
			end
			if @host
				data += "\n" + 'user_pref("network.http", "' + @host || "" + '");'
				if @port 
					data += "\n" + 'user_pref("network.http_port", "' + @port || "" + '");'
				end
			end
			puts "done setting firefox"


		end

		def set_env!(reset)
			if reset
				open("#{ENV['HOME']}/.pwnpr0xy.sh", "w") do |f|
					f.write "# no proxy set."
				end
			else
			open("#{ENV['HOME']}/.pwnpr0xy.sh", "w") do |f|
					f.write "export HTTP_PROXY=#{proxy_url}\n"
					f.write "export HTTPS_PROXY=#{proxy_url}"
				end
				puts "Done adding proxy to shell. Reload your shell to set the changes."
			end
		end

		def set_systemwide!(reset=nil)
			puts "We need root access to enable proxy in macosx: "
			`sudo networksetup -setwebproxy Wi-Fi #{proxy_url}`
			if reset
				`sudo networksetup -setwebproxy Wi-Fi off`
			end
		end
	end

	class Rule

	end
end
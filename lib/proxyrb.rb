module ProxyRB
	class IP
		attr_reader :v4
		def initialize
			@v4 = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
		end
	end

	class Proxy
		attr_accessor :host, :port, :username, :password
		def initialize

		end

		def set_git!
		end

		def set_firefox!
		end

		def set_env!
		end

		def set_systemwide!
		end
	end

	class Rule

	end
end
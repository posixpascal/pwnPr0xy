# pwnpr0xy and proxyrb

## pwnpr0xy
Man. School Proxies suck. No matter how well they are configured, it's always a pain in the ass to deal with proxies.
Especially if you're a developer. In my case for example I need to switch between home/school/work environments pretty often.
Setting a proxy in MacOSX system settings doesn't apply to command line programs like git or programs like firefox.
Another annoying thing when dealing with proxies are shell sessions. They usually require an HTTP environment flag to be set... (garn).

That's why I wrote pwnpr0xy which automagically sets/remove proxies based on a simple but powerful rule system.
First install pwnpr0xy using `gem` or `bundler` (I will release the gem soon). Then write your own custom `proxyrb.yml` like mine below:

```yaml
proxies: # general key, this is required
    school: # a proxy name
        protocols: # not supported yet (always defaults to HTTP, HTTPS)
        - HTTP
        - HTTPS
        - SOCKS

        host: 192.168.10.10 # obvious
        port: 80

        env: true # set environment HTTP variables
        systemwide: true # set macosx system proxy
        git: true # add git http.proxy to config
        firefox: true # add proxy to firefox


networks: # general key, required as well.
    school: # a network name
        proxy: school # which proxy to use
        detect_by: # required, how to detect this network
            ping: # rule (see below)
            - 192.168.10.10 # argument array

    home: # same
        proxy: none # no proxy
        detect_by: 
            iprange:
            - 192.168.178.0/24


    work: 
        proxy: none
        detect_by:
            iprange:
            - 10.0.0.0/24

    default: home
```

#### The rule system
Every network is somehow identifiable using the IP, or the range etc.
As soon as all(!!) `detect_by` rules return true, the proxy for the network will be set.
Atm. I support the following rules:

* ip: checks your current ip with the one in your config
* iprange: checks whether or not your current ip is in an ip range
* ping: checks if certain adresses are reachable in your network

You can write custom rules easily. Just change the rule name (eg. Device) to something else.
*pwnPr0xy* will look for a class _YourRuleNameRule_  (eg. DeviceRule).
These rules have to follow the following format:

```ruby
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
```

*to be continued*


## proxyrb
proxyrb is a gem which sets a proxy for different applications. It's in an early and unusable state, do not use in production pls.
I will add more documentation later, but you can use it like this:
```
require 'proxyrb'
proxy = Proxy.new({
	:host => "192.168.10.10",
	:port => 80
})

proxy.set({
	:firefox => true,
	:env => false
});
```

It only works for *MacOSX* at the moment, I will add linux support (or not because I don't need Linux at school/work).
You will have to reload your shell after executing proxyrb. Firefox might not work during development of this gem.
Git will always change the global config. If you don't like that, remove the **--global** flag in the source code.

# Documentation
pls. stahp.

# License
GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007

Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>

Everyone is permitted to copy and distribute verbatim copies of this license document, **changing it is not allowed.**
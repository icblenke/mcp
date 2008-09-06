#!/usr/bin/env ruby

require 'syslog'
require 'drb'
require 'drb/unix'

#
## Constants
##
PLUGINS_DIR = 'plugins.d'

class MCPDaemon
        attr_accessor :plugins

	def plugin_command(name,args,stdin,stdout,stderr)
		@plugin=@plugins[name]
		@plugin.command(args,stdin,stdout,stderr)
	end

	def plugin_load(name)
		if not @plugins[name]
			@file="#{PLUGINS_DIR}/#{name}.rb"
			begin
				load "#{@file}"
				eval "@plugin=#{name}.new(self)"
				@plugin.mtime=File.stat(@file).mtime
				@plugins[name]=@plugin
				log("Loaded plugin: #{name} (#{@plugin.mtime})")
			rescue => detail
				log("Error loading plugin: #{name}: #{detail.message}")
			end
		end
		@plugins.has_key?(name)
	end


	def plugin_unload(name)
		if @plugins[name]
			begin
				@plugins[name].unload()
				log("Unloaded plugin: #{name} (#{@plugins[name].mtime})")
				@plugins.delete(name)
			rescue => detail
				log("Error unloading plugin: #{name}: #{detail.message}")
			end
			not @plugins.has_key?(name)
		end
	end


	def plugins_scan()
		begin
			@plugin_files={}
			Dir["#{PLUGINS_DIR}/*"].each do |file|
				name=File.basename(file).sub!(/\.rb\Z/,'')
				@plugin_files[name]=file
			end
			
			@plugin_files.each do |name,file|
				if @plugins && @plugins.has_key?(name)
					if File.stat(file).mtime != @plugins[name].mtime
						plugin_unload(name)
						plugin_load(name)
					end
				else
					plugin_load(name)
				end
			end

			@plugins.each do |name,plugin|
				if not @plugin_files.has_key?(name)
					plugin_unload(name)
				end
			end
		rescue => detail
			log(detail.backtrace.join("\n"))
		end
	end

        def log(message)
                @syslog.info(message)
        end  

        def command(argv,stdin,stdout,stderr)
                @command=argv.join(' ')
                begin
                        log("Client said to run #{@command}")
                        stdout.puts "You said to run #{@command}\n"
			name=argv.shift
			plugin_command(name,argv,stdin,stdout,stderr)
                rescue => detail
                        stderr.puts detail.message + "\n"
                        stderr.puts detail.backtrace.join("\n") + "\n"
                        1
                end
        end

        def initialize
                @syslog=Syslog.open( File.basename(__FILE__),
                                                   Syslog::LOG_PERROR |
                                                   Syslog::LOG_NDELAY )

		@plugins={}

		# Plugin handler thread
		Thread.new do
			while true do
				plugins_scan()
				sleep 1
			end             
		end 

                # More initialization here.
                DRb.start_service "drbunix:/tmp/mcpd.sock", self
                log("Daemon started")
                DRb.thread.join
        end
end

MCPDaemon.new

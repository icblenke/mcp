class Tron
        attr_accessor :running, :mtime, :thread, :daemon

        def command(arg,stdin,stdout,stderr)
                @daemon.log("Tron received command #{arg}")
		stdout.print "Greetings user. Nothing to report. You said '#{arg}'.\n"
		0
        end

        def unload
                @running=false
        end

        def stop
                @running=false
                @thread.join
                "Tron thread stopped.\n"
        end

        def start
                if not @running
                        @running=true
                        @thread=Thread.new do
                                @daemon.log("Tron thread started (#{@mtime})")
                                Thread.current['name']="Tron thread"
                                while @running do
                                        sleep 10
                                end
                                @daemon.log("Tron thread ending (#{@mtime})")
                        end
                        "Tron thread started\n"
                else
                        "Tron thread already running\n"
                end
        end

        def initialize(daemon)
                @daemon=daemon
                start()
        end

end

#!/usr/bin/env ruby

require 'drb'
require 'drb/unix'

begin
        DRb.start_service
        mcpd = DRbObject.new nil, "drbunix:/tmp/mcpd.sock"
        $stdin.extend DRbUndumped
        $stdout.extend DRbUndumped
        $stderr.extend DRbUndumped
        mcpd.command(ARGV, $stdin, $stdout, $stderr)
rescue
        print "ERROR: unable to communicate with mcpd: #{$!} in #{$@}\n"
	exit 1
end

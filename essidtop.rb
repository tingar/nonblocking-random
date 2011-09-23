#!/usr/bin/ruby

def get_stats(card)
	vals = {}

	cell = nil
	current = {
		:mac     => '??:??:??:??:??:??',
		:essid   => 'Unknown',
		:channel => '-1',
		:snratio => 0,
		:key     => '???'
	}

	%x[/usr/sbin/iwlist #{card} scan].each_line do |ln|
		ln.chomp!
		ln.gsub!(/^\s+/, '')
		ln.gsub!(/\s+$/, '')

		case ln
			when /^Cell ([[:digit:]]+) - Address: ([A-Fa-f[:digit:]:]+)$/ then
				unless (cell.nil?) then
					vals[cell] = current
					current = {
						:mac     => '??:??:??:??:??:??',
						:essid   => 'Unknown',
						:channel => '-1',
						:snratio => 0,
						:key     => '???'
					}
				end

				cell = $1
				current[:mac] = $2

			when /^ESSID:"(.*)"$/ then
				current[:essid] = $1

			when /^Channel:([[:digit:]]+)$/ then
				current[:channel] = $1

			when /^Quality=([[:digit:]]+)\/([[:digit:]]+)\s/ then
				current[:snratio] = (100 * ($1.to_f / $2.to_f)).to_i

			when /^Encryption key:(on|off)/ then
				current[:key] = $1

			else
				#puts "Unmatched: '#{ln}'"
		end
	end

	unless (cell.nil?) then
		vals[cell] = current
	end

	vals
end

card = ARGV[0]

loop do
	stats = get_stats card

	if ($stdout.isatty) then
		printf "\e[H\e[2J"
	end

	# foreach key in stats
	printf "Cell %-17s Ch SN Enc ESSID\n" % 'Mac'
	stats.each do |k,v|
		# print out line
		printf "%-4s %-17s %02d %02d %3s %s\n" % [k, v[:mac], v[:channel].to_i,v[:snratio], v[:key], v[:essid]]
	end

	sleep 10
end

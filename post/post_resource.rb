require 'msf/core'

class Metasploit3 < Msf::Auxiliary
	include Msf::Ui::Console
	def initialize(info={})
		super( update_info( info,
				'Name'          => 'Post Module Resource file Automation Module',
				'Description'   => %q{ Run resource file with post modules and options
									against specified sessions.},
				'License'       => "BSD",
				'Author'        => [ 'Carlos Perez <carlos_perez[at]darkoperator.com>'],
				'Version'       => '$Revision$'
			))
		register_options(
			[
				OptString.new('RESOURCE', [true, 'Resource file with space separate values <session> <module> <options>, per line.', nil])

			], self.class)
	end

	# Run Method for when run command is issued
	def run
		entries = []
		current_sessions = framework.sessions.keys.sort
		script = datastore['RESOURCE']
		if ::File.exist?(script)
			::File.open(script, "r").each_line do |line|
				# Empty line
				next if line.strip.length < 1
				# Comment
				next if line[0,1] == "#"
				entries << line.chomp
			end
		else
			print_error("Resourse file does not exist.")
		end

		if entries
			entries.each do |l|
				values = l.split(" ")
				sessions = values[0]
				if values[1] =~ /^post/
					post_mod = values[1].gsub(/^post\//,"")
				else
					post_mod = values[1]
				end
				
				if values.length == 3
					mod_opts = values[2].split(",")
				end
				print_status("Loading #{post_mod}")
				m= framework.post.create(post_mod)
				if sessions =~ /all/i
					session_list = m.compatible_sessions
				else
					session_list = sessions.split(",")
				end
				if session_list
					session_list.each do |s|
						next if not current_sessions.include?(s.to_i)
						if m.session_compatible?(s.to_i)
							print_status("Running Against #{s}")
							m.datastore['SESSION'] = s.to_i
							if mod_opts
								mod_opts.each do |o|
									opt_pair = o.split("=",2)
									print_status("\tSetting Option #{opt_pair[0]} to #{opt_pair[1]}")
									m.datastore[opt_pair[0]] = opt_pair[1]
								end
							end
							m.options.validate(m.datastore)
							m.run_simple(
								'LocalInput'    => self.user_input,
								'LocalOutput'    => self.user_output
							)
						else
							print_error("Session #{s} is not compatible with #{post_mod}")
						end
					end
				else
					print_error("No Compatible Sessions where found!")
				end
			end
		end
	end

	
end
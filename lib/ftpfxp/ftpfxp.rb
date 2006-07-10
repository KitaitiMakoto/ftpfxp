=begin
	= ftpfxp.rb - FXP enhancements to the basic FTP Client Library.
	Copyright (C)2006, Alex Lee. All Rights Reserved.

 	Written by Alex Lee <alexeen@noservice.net>.

	This library is distributed under the terms of the Ruby license.
	You can freely distribute/modify this library.
=end
require 'net/ftp'

module Net
	class FTPFXP < FTP

		# Issue the FEAT command to dump a list of FTP extensions supported
		# by this FTP server.
		def feat
			synchronize do
				putline('FEAT')
				return getresp
			end
		end

		# Sets the extended dupe checking mode on the ftp server.
		# If no mode specified, it returns the current mode.
		# mode=0 : Disables the extended dupe checking mode.
		# mode=1 : X-DUPE replies several file names per line.
		# mode=2 : Server replies with one file name per X-DUPE line.
		# mode=3 : Server replies with one filename per X-DUPE line with no truncation.
		# mode=4 : All files listed in one long line up to max 1024 characters.
		# For details, visit http://www.smartftp.com/Products/SmartFTP/RFC/x-dupe-info.txt
		def xdupe(mode=nil)
			synchronize do
				if mode.nil?
					putline('SITE XDUPE')
					return getresp
				else
					putline("SITE XDUPE #{mode.to_i}")
					return getresp
				end
			end
		end

		# Returns the passive port values on this ftp server.
		def fxpgetpasvport
			synchronize do
				# Get the passive IP and port values for next transfer.
				putline('PASV')
				return getresp
			end
		end

		# Sets the IP and port for next transfer on this ftp server.
		def fxpsetport(ipnport)
			synchronize do
				putline("PORT #{ipnport}")
				return getresp
			end
		end

		# This is called on the destination side of the FXP.
		# This should be called before fxpretr.
		def fxpstor(file)
			synchronize do
				voidcmd('TYPE I')
				putline("STOR #{file}")
				return getresp
			end
		end

		# This is called on the source side of the FXP.
		# This should be called after fxpstor.
		def fxpretr(file)
			synchronize do
				voidcmd('TYPE I')
				putline("RETR #{file}")
				return getresp
			end
		end

		# This waits for the FXP to finish on the current ftp server.
		# If this is the source, it should return 226 Transfer Complete,
		# on success. If this is the destination, it should return
		# 226 File receive OK.
		def fxpwait
			synchronize do
				return getresp
			end
		end

		# This FXP the specified source path to the destination path
		# on the destination site. Path names should be for files only.
		def fxpto(dst, dstpath, srcpath)
			pline = fxpgetpasvport
			comp = pline.split(/\s+/)
			ports = String.new(comp[4].gsub('(', '').gsub(')', ''))
			dst.fxpsetport(ports)
			dst.fxpstor(dstpath)
			fxpretr(srcpath)
			resp = fxpwait
			raise "#{resp}" unless '226' == resp[0,3]
			resp = dst.fxpwait
			raise "#{resp}" unless '226' == resp[0,3]
			return resp
		end

		# This is a faster implementation of LIST where we use STAT -l
		# on supported servers. (All latest versions of ftp servers should
		# support this!) The path argument is optional, but it will call
		# STAT -l on the path if it is specified.
		def fastlist(path = nil)
			synchronize do
				if path.nil?
				  putline('STAT -l')
				else
				  putline("STAT -l #{path}")
				end
				return getresp
			end
		end

		# Check if a file path exists.
		def fileExists(path)
			resp = fastlist(path)
			stats = false
			resp.each do |entry|
				next if '213' == entry[0,3] # Skip these useless lines.
				status = true if '-rw' == entry[0,3]
			end
			return resp
		end
	end
end

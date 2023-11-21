# typed: false

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `net-smtp` gem.
# Please instead update this file by running `bin/tapioca gem net-smtp`.

# == What is This Library?
#
# This library provides functionality to send internet
# mail via SMTP, the Simple Mail Transfer Protocol. For details of
# SMTP itself, see [RFC5321] (http://www.ietf.org/rfc/rfc5321.txt).
# This library also implements SMTP authentication, which is often
# necessary for message composers to submit messages to their
# outgoing SMTP server, see
# [RFC6409](http://www.ietf.org/rfc/rfc6503.txt),
# and [SMTPUTF8](http://www.ietf.org/rfc/rfc6531.txt), which is
# necessary to send messages to/from addresses containing characters
# outside the ASCII range.
#
# == What is This Library NOT?
#
# This library does NOT provide functions to compose internet mails.
# You must create them by yourself. If you want better mail support,
# try RubyMail or TMail or search for alternatives in
# {RubyGems.org}[https://rubygems.org/] or {The Ruby
# Toolbox}[https://www.ruby-toolbox.com/].
#
# FYI: the official specification on internet mail is: [RFC5322] (http://www.ietf.org/rfc/rfc5322.txt).
#
# == Examples
#
# === Sending Messages
#
# You must open a connection to an SMTP server before sending messages.
# The first argument is the address of your SMTP server, and the second
# argument is the port number. Using SMTP.start with a block is the simplest
# way to do this. This way, the SMTP connection is closed automatically
# after the block is executed.
#
#     require 'net/smtp'
#     Net::SMTP.start('your.smtp.server', 25) do |smtp|
#       # Use the SMTP object smtp only in this block.
#     end
#
# Replace 'your.smtp.server' with your SMTP server. Normally
# your system manager or internet provider supplies a server
# for you.
#
# Then you can send messages.
#
#     msgstr = <<END_OF_MESSAGE
#     From: Your Name <your@mail.address>
#     To: Destination Address <someone@example.com>
#     Subject: test message
#     Date: Sat, 23 Jun 2001 16:26:43 +0900
#     Message-Id: <unique.message.id.string@example.com>
#
#     This is a test message.
#     END_OF_MESSAGE
#
#     require 'net/smtp'
#     Net::SMTP.start('your.smtp.server', 25) do |smtp|
#       smtp.send_message msgstr,
#                         'your@mail.address',
#                         'his_address@example.com'
#     end
#
# === Closing the Session
#
# You MUST close the SMTP session after sending messages, by calling
# the #finish method:
#
#     # using SMTP#finish
#     smtp = Net::SMTP.start('your.smtp.server', 25)
#     smtp.send_message msgstr, 'from@address', 'to@address'
#     smtp.finish
#
# You can also use the block form of SMTP.start/SMTP#start.  This closes
# the SMTP session automatically:
#
#     # using block form of SMTP.start
#     Net::SMTP.start('your.smtp.server', 25) do |smtp|
#       smtp.send_message msgstr, 'from@address', 'to@address'
#     end
#
# I strongly recommend this scheme.  This form is simpler and more robust.
#
# === HELO domain
#
# In almost all situations, you must provide a third argument
# to SMTP.start/SMTP#start. This is the domain name which you are on
# (the host to send mail from). It is called the "HELO domain".
# The SMTP server will judge whether it should send or reject
# the SMTP session by inspecting the HELO domain.
#
#     Net::SMTP.start('your.smtp.server', 25
#                     helo: 'mail.from.domain') { |smtp| ... }
#
# === SMTP Authentication
#
# The Net::SMTP class supports three authentication schemes;
# PLAIN, LOGIN and CRAM MD5.  (SMTP Authentication: [RFC2554])
# To use SMTP authentication, pass extra arguments to
# SMTP.start/SMTP#start.
#
#     # PLAIN
#     Net::SMTP.start('your.smtp.server', 25
#                     user: 'Your Account', secret: 'Your Password', authtype: :plain)
#     # LOGIN
#     Net::SMTP.start('your.smtp.server', 25
#                     user: 'Your Account', secret: 'Your Password', authtype: :login)
#
#     # CRAM MD5
#     Net::SMTP.start('your.smtp.server', 25
#                     user: 'Your Account', secret: 'Your Password', authtype: :cram_md5)
#
# source://net-smtp/lib/net/smtp.rb#189
class Net::SMTP < ::Net::Protocol
  # Creates a new Net::SMTP object.
  #
  # +address+ is the hostname or ip address of your SMTP
  # server.  +port+ is the port to connect to; it defaults to
  # port 25.
  #
  # If +tls+ is true, enable TLS. The default is false.
  # If +starttls+ is :always, enable STARTTLS, if +:auto+, use STARTTLS when the server supports it,
  # if false, disable STARTTLS.
  #
  # If +tls_verify+ is true, verify the server's certificate. The default is true.
  # If the hostname in the server certificate is different from +address+,
  # it can be specified with +tls_hostname+.
  #
  # Additional SSLContext params can be added to +ssl_context_params+ hash argument and are passed to
  # +OpenSSL::SSL::SSLContext#set_params+
  #
  # +tls_verify: true+ is equivalent to +ssl_context_params: { verify_mode: OpenSSL::SSL::VERIFY_PEER }+.
  # This method does not open the TCP connection.  You can use
  # SMTP.start instead of SMTP.new if you want to do everything
  # at once.  Otherwise, follow SMTP.new with SMTP#start.
  #
  # @return [SMTP] a new instance of SMTP
  #
  # source://net-smtp/lib/net/smtp.rb#240
  def initialize(address, port = T.unsafe(nil), tls: T.unsafe(nil), starttls: T.unsafe(nil), tls_verify: T.unsafe(nil), tls_hostname: T.unsafe(nil), ssl_context_params: T.unsafe(nil)); end

  # The address of the SMTP server to connect to.
  #
  # source://net-smtp/lib/net/smtp.rb#405
  def address; end

  # source://net-smtp/lib/net/smtp.rb#834
  def authenticate(user, secret, authtype = T.unsafe(nil)); end

  # The server capabilities by EHLO response
  #
  # source://net-smtp/lib/net/smtp.rb#299
  def capabilities; end

  # true if the EHLO response contains +key+.
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#293
  def capable?(key); end

  # Returns supported authentication methods on this server.
  # You cannot get valid value before opening SMTP session.
  #
  # source://net-smtp/lib/net/smtp.rb#328
  def capable_auth_types; end

  # true if server advertises AUTH CRAM-MD5.
  # You cannot get valid value before opening SMTP session.
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#315
  def capable_cram_md5_auth?; end

  # true if server advertises AUTH LOGIN.
  # You cannot get valid value before opening SMTP session.
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#309
  def capable_login_auth?; end

  # true if server advertises AUTH PLAIN.
  # You cannot get valid value before opening SMTP session.
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#303
  def capable_plain_auth?; end

  # true if server advertises STARTTLS.
  # You cannot get valid value before opening SMTP session.
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#288
  def capable_starttls?; end

  # This method sends a message.
  # If +msgstr+ is given, sends it as a message.
  # If block is given, yield a message writer stream.
  # You must write message before the block is closed.
  #
  #   # Example 1 (by string)
  #   smtp.data(<<EndMessage)
  #   From: john@example.com
  #   To: betty@example.com
  #   Subject: I found a bug
  #
  #   Check vm.c:58879.
  #   EndMessage
  #
  #   # Example 2 (by block)
  #   smtp.data {|f|
  #     f.puts "From: john@example.com"
  #     f.puts "To: betty@example.com"
  #     f.puts "Subject: I found a bug"
  #     f.puts ""
  #     f.puts "Check vm.c:58879."
  #   }
  #
  # source://net-smtp/lib/net/smtp.rb#933
  def data(msgstr = T.unsafe(nil), &block); end

  # WARNING: This method causes serious security holes.
  # Use this method for only debugging.
  #
  # Set an output stream for debug logging.
  # You must call this before #start.
  #
  #   # example
  #   smtp = Net::SMTP.new(addr, port)
  #   smtp.set_debug_output $stderr
  #   smtp.start do |smtp|
  #     ....
  #   end
  #
  # source://net-smtp/lib/net/smtp.rb#441
  def debug_output=(arg); end

  # Disables SMTP/TLS for this object.  Must be called before the
  # connection is established to have any effect.
  #
  # source://net-smtp/lib/net/smtp.rb#355
  def disable_ssl; end

  # Disables SMTP/TLS (STARTTLS) for this object.  Must be called
  # before the connection is established to have any effect.
  #
  # source://net-smtp/lib/net/smtp.rb#399
  def disable_starttls; end

  # Disables SMTP/TLS for this object.  Must be called before the
  # connection is established to have any effect.
  #
  # source://net-smtp/lib/net/smtp.rb#355
  def disable_tls; end

  # source://net-smtp/lib/net/smtp.rb#882
  def ehlo(domain); end

  # Enables SMTP/TLS (SMTPS: SMTP over direct TLS connection) for
  # this object.  Must be called before the connection is established
  # to have any effect.  +context+ is a OpenSSL::SSL::SSLContext object.
  #
  # @raise [ArgumentError]
  #
  # source://net-smtp/lib/net/smtp.rb#344
  def enable_ssl(context = T.unsafe(nil)); end

  # Enables SMTP/TLS (STARTTLS) for this object.
  # +context+ is a OpenSSL::SSL::SSLContext object.
  #
  # @raise [ArgumentError]
  #
  # source://net-smtp/lib/net/smtp.rb#381
  def enable_starttls(context = T.unsafe(nil)); end

  # Enables SMTP/TLS (STARTTLS) for this object if server accepts.
  # +context+ is a OpenSSL::SSL::SSLContext object.
  #
  # @raise [ArgumentError]
  #
  # source://net-smtp/lib/net/smtp.rb#390
  def enable_starttls_auto(context = T.unsafe(nil)); end

  # Enables SMTP/TLS (SMTPS: SMTP over direct TLS connection) for
  # this object.  Must be called before the connection is established
  # to have any effect.  +context+ is a OpenSSL::SSL::SSLContext object.
  #
  # @raise [ArgumentError]
  #
  # source://net-smtp/lib/net/smtp.rb#344
  def enable_tls(context = T.unsafe(nil)); end

  # Set whether to use ESMTP or not.  This should be done before
  # calling #start.  Note that if #start is called in ESMTP mode,
  # and the connection fails due to a ProtocolError, the SMTP
  # object will automatically switch to plain SMTP mode and
  # retry (but not vice versa).
  #
  # source://net-smtp/lib/net/smtp.rb#281
  def esmtp; end

  # Set whether to use ESMTP or not.  This should be done before
  # calling #start.  Note that if #start is called in ESMTP mode,
  # and the connection fails due to a ProtocolError, the SMTP
  # object will automatically switch to plain SMTP mode and
  # retry (but not vice versa).
  #
  # source://net-smtp/lib/net/smtp.rb#281
  def esmtp=(_arg0); end

  # Set whether to use ESMTP or not.  This should be done before
  # calling #start.  Note that if #start is called in ESMTP mode,
  # and the connection fails due to a ProtocolError, the SMTP
  # object will automatically switch to plain SMTP mode and
  # retry (but not vice versa).
  # +true+ if the SMTP object uses ESMTP (which it does by default).
  #
  # source://net-smtp/lib/net/smtp.rb#281
  def esmtp?; end

  # Finishes the SMTP session and closes TCP connection.
  # Raises IOError if not started.
  #
  # @raise [IOError]
  #
  # source://net-smtp/lib/net/smtp.rb#623
  def finish; end

  # source://net-smtp/lib/net/smtp.rb#964
  def get_response(reqline); end

  # source://net-smtp/lib/net/smtp.rb#878
  def helo(domain); end

  # Provide human-readable stringification of class state.
  #
  # source://net-smtp/lib/net/smtp.rb#270
  def inspect; end

  # +from_addr+ is +String+ or +Net::SMTP::Address+
  #
  # source://net-smtp/lib/net/smtp.rb#887
  def mailfrom(from_addr); end

  # Opens a message writer stream and gives it to the block.
  # The stream is valid only in the block, and has these methods:
  #
  # puts(str = '')::       outputs STR and CR LF.
  # print(str)::           outputs STR.
  # printf(fmt, *args)::   outputs sprintf(fmt,*args).
  # write(str)::           outputs STR and returns the length of written bytes.
  # <<(str)::              outputs STR and returns self.
  #
  # If a single CR ("\r") or LF ("\n") is found in the message,
  # it is converted to the CR LF pair.  You cannot send a binary
  # message with this method.
  #
  # === Parameters
  #
  # +from_addr+ is a String or Net::SMTP::Address representing the source mail address.
  #
  # +to_addr+ is a String or Net::SMTP::Address or Array of them, representing
  # the destination mail address or addresses.
  #
  # === Example
  #
  #     Net::SMTP.start('smtp.example.com', 25) do |smtp|
  #       smtp.open_message_stream('from@example.com', ['dest@example.com']) do |f|
  #         f.puts 'From: from@example.com'
  #         f.puts 'To: dest@example.com'
  #         f.puts 'Subject: test message'
  #         f.puts
  #         f.puts 'This is a test message.'
  #       end
  #     end
  #
  # === Errors
  #
  # This method may raise:
  #
  # * Net::SMTPServerBusy
  # * Net::SMTPSyntaxError
  # * Net::SMTPFatalError
  # * Net::SMTPUnknownError
  # * Net::ReadTimeout
  # * IOError
  #
  # @raise [IOError]
  #
  # source://net-smtp/lib/net/smtp.rb#818
  def open_message_stream(from_addr, *to_addrs, &block); end

  # Seconds to wait while attempting to open a connection.
  # If the connection cannot be opened within this time, a
  # Net::OpenTimeout is raised. The default value is 30 seconds.
  #
  # source://net-smtp/lib/net/smtp.rb#413
  def open_timeout; end

  # Seconds to wait while attempting to open a connection.
  # If the connection cannot be opened within this time, a
  # Net::OpenTimeout is raised. The default value is 30 seconds.
  #
  # source://net-smtp/lib/net/smtp.rb#413
  def open_timeout=(_arg0); end

  # The port number of the SMTP server to connect to.
  #
  # source://net-smtp/lib/net/smtp.rb#408
  def port; end

  # source://net-smtp/lib/net/smtp.rb#960
  def quit; end

  # +to_addr+ is +String+ or +Net::SMTP::Address+
  #
  # source://net-smtp/lib/net/smtp.rb#905
  def rcptto(to_addr); end

  # @raise [ArgumentError]
  #
  # source://net-smtp/lib/net/smtp.rb#896
  def rcptto_list(to_addrs); end

  # Seconds to wait while reading one block (by one read(2) call).
  # If the read(2) call does not complete within this time, a
  # Net::ReadTimeout is raised. The default value is 60 seconds.
  #
  # source://net-smtp/lib/net/smtp.rb#418
  def read_timeout; end

  # Set the number of seconds to wait until timing-out a read(2)
  # call.
  #
  # source://net-smtp/lib/net/smtp.rb#422
  def read_timeout=(sec); end

  # Opens a message writer stream and gives it to the block.
  # The stream is valid only in the block, and has these methods:
  #
  # puts(str = '')::       outputs STR and CR LF.
  # print(str)::           outputs STR.
  # printf(fmt, *args)::   outputs sprintf(fmt,*args).
  # write(str)::           outputs STR and returns the length of written bytes.
  # <<(str)::              outputs STR and returns self.
  #
  # If a single CR ("\r") or LF ("\n") is found in the message,
  # it is converted to the CR LF pair.  You cannot send a binary
  # message with this method.
  #
  # === Parameters
  #
  # +from_addr+ is a String or Net::SMTP::Address representing the source mail address.
  #
  # +to_addr+ is a String or Net::SMTP::Address or Array of them, representing
  # the destination mail address or addresses.
  #
  # === Example
  #
  #     Net::SMTP.start('smtp.example.com', 25) do |smtp|
  #       smtp.open_message_stream('from@example.com', ['dest@example.com']) do |f|
  #         f.puts 'From: from@example.com'
  #         f.puts 'To: dest@example.com'
  #         f.puts 'Subject: test message'
  #         f.puts
  #         f.puts 'This is a test message.'
  #       end
  #     end
  #
  # === Errors
  #
  # This method may raise:
  #
  # * Net::SMTPServerBusy
  # * Net::SMTPSyntaxError
  # * Net::SMTPFatalError
  # * Net::SMTPUnknownError
  # * Net::ReadTimeout
  # * IOError
  # obsolete
  #
  # @raise [IOError]
  #
  # source://net-smtp/lib/net/smtp.rb#818
  def ready(from_addr, *to_addrs, &block); end

  # Aborts the current mail transaction
  #
  # source://net-smtp/lib/net/smtp.rb#870
  def rset; end

  # Sends +msgstr+ as a message.  Single CR ("\r") and LF ("\n") found
  # in the +msgstr+, are converted into the CR LF pair.  You cannot send a
  # binary message with this method. +msgstr+ should include both
  # the message headers and body.
  #
  # +from_addr+ is a String or Net::SMTP::Address representing the source mail address.
  #
  # +to_addr+ is a String or Net::SMTP::Address or Array of them, representing
  # the destination mail address or addresses.
  #
  # === Example
  #
  #     Net::SMTP.start('smtp.example.com') do |smtp|
  #       smtp.send_message msgstr,
  #                         'from@example.com',
  #                         ['dest@example.com', 'dest2@example.com']
  #     end
  #
  #     Net::SMTP.start('smtp.example.com') do |smtp|
  #       smtp.send_message msgstr,
  #                         Net::SMTP::Address.new('from@example.com', size: 12345),
  #                         Net::SMTP::Address.new('dest@example.com', notify: :success)
  #     end
  #
  # === Errors
  #
  # This method may raise:
  #
  # * Net::SMTPServerBusy
  # * Net::SMTPSyntaxError
  # * Net::SMTPFatalError
  # * Net::SMTPUnknownError
  # * Net::ReadTimeout
  # * IOError
  #
  # @raise [IOError]
  #
  # source://net-smtp/lib/net/smtp.rb#763
  def send_mail(msgstr, from_addr, *to_addrs); end

  # Sends +msgstr+ as a message.  Single CR ("\r") and LF ("\n") found
  # in the +msgstr+, are converted into the CR LF pair.  You cannot send a
  # binary message with this method. +msgstr+ should include both
  # the message headers and body.
  #
  # +from_addr+ is a String or Net::SMTP::Address representing the source mail address.
  #
  # +to_addr+ is a String or Net::SMTP::Address or Array of them, representing
  # the destination mail address or addresses.
  #
  # === Example
  #
  #     Net::SMTP.start('smtp.example.com') do |smtp|
  #       smtp.send_message msgstr,
  #                         'from@example.com',
  #                         ['dest@example.com', 'dest2@example.com']
  #     end
  #
  #     Net::SMTP.start('smtp.example.com') do |smtp|
  #       smtp.send_message msgstr,
  #                         Net::SMTP::Address.new('from@example.com', size: 12345),
  #                         Net::SMTP::Address.new('dest@example.com', notify: :success)
  #     end
  #
  # === Errors
  #
  # This method may raise:
  #
  # * Net::SMTPServerBusy
  # * Net::SMTPSyntaxError
  # * Net::SMTPFatalError
  # * Net::SMTPUnknownError
  # * Net::ReadTimeout
  # * IOError
  #
  # @raise [IOError]
  #
  # source://net-smtp/lib/net/smtp.rb#763
  def send_message(msgstr, from_addr, *to_addrs); end

  # Sends +msgstr+ as a message.  Single CR ("\r") and LF ("\n") found
  # in the +msgstr+, are converted into the CR LF pair.  You cannot send a
  # binary message with this method. +msgstr+ should include both
  # the message headers and body.
  #
  # +from_addr+ is a String or Net::SMTP::Address representing the source mail address.
  #
  # +to_addr+ is a String or Net::SMTP::Address or Array of them, representing
  # the destination mail address or addresses.
  #
  # === Example
  #
  #     Net::SMTP.start('smtp.example.com') do |smtp|
  #       smtp.send_message msgstr,
  #                         'from@example.com',
  #                         ['dest@example.com', 'dest2@example.com']
  #     end
  #
  #     Net::SMTP.start('smtp.example.com') do |smtp|
  #       smtp.send_message msgstr,
  #                         Net::SMTP::Address.new('from@example.com', size: 12345),
  #                         Net::SMTP::Address.new('dest@example.com', notify: :success)
  #     end
  #
  # === Errors
  #
  # This method may raise:
  #
  # * Net::SMTPServerBusy
  # * Net::SMTPSyntaxError
  # * Net::SMTPFatalError
  # * Net::SMTPUnknownError
  # * Net::ReadTimeout
  # * IOError
  # obsolete
  #
  # @raise [IOError]
  #
  # source://net-smtp/lib/net/smtp.rb#763
  def sendmail(msgstr, from_addr, *to_addrs); end

  # WARNING: This method causes serious security holes.
  # Use this method for only debugging.
  #
  # Set an output stream for debug logging.
  # You must call this before #start.
  #
  #   # example
  #   smtp = Net::SMTP.new(addr, port)
  #   smtp.set_debug_output $stderr
  #   smtp.start do |smtp|
  #     ....
  #   end
  #
  # source://net-smtp/lib/net/smtp.rb#441
  def set_debug_output(arg); end

  # true if this object uses SMTP/TLS (SMTPS).
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#335
  def ssl?; end

  # Hash for additional SSLContext parameters.
  #
  # source://net-smtp/lib/net/smtp.rb#267
  def ssl_context_params; end

  # Hash for additional SSLContext parameters.
  #
  # source://net-smtp/lib/net/smtp.rb#267
  def ssl_context_params=(_arg0); end

  # :call-seq:
  #  start(helo: 'localhost', user: nil, secret: nil, authtype: nil) { |smtp| ... }
  #  start(helo = 'localhost', user = nil, secret = nil, authtype = nil) { |smtp| ... }
  #
  # Opens a TCP connection and starts the SMTP session.
  #
  # === Parameters
  #
  # +helo+ is the _HELO_ _domain_ that you'll dispatch mails from; see
  # the discussion in the overview notes.
  #
  # If both of +user+ and +secret+ are given, SMTP authentication
  # will be attempted using the AUTH command.  +authtype+ specifies
  # the type of authentication to attempt; it must be one of
  # :login, :plain, and :cram_md5.  See the notes on SMTP Authentication
  # in the overview.
  #
  # === Block Usage
  #
  # When this methods is called with a block, the newly-started SMTP
  # object is yielded to the block, and automatically closed after
  # the block call finishes.  Otherwise, it is the caller's
  # responsibility to close the session when finished.
  #
  # === Example
  #
  # This is very similar to the class method SMTP.start.
  #
  #     require 'net/smtp'
  #     smtp = Net::SMTP.new('smtp.mail.server', 25)
  #     smtp.start(helo: helo_domain, user: account, secret: password, authtype: authtype) do |smtp|
  #       smtp.send_message msgstr, 'from@example.com', ['dest@example.com']
  #     end
  #
  # The primary use of this method (as opposed to SMTP.start)
  # is probably to set debugging (#set_debug_output) or ESMTP
  # (#esmtp=), which must be done before the session is
  # started.
  #
  # === Errors
  #
  # If session has already been started, an IOError will be raised.
  #
  # This method may raise:
  #
  # * Net::SMTPAuthenticationError
  # * Net::SMTPServerBusy
  # * Net::SMTPSyntaxError
  # * Net::SMTPFatalError
  # * Net::SMTPUnknownError
  # * Net::OpenTimeout
  # * Net::ReadTimeout
  # * IOError
  #
  # @raise [ArgumentError]
  #
  # source://net-smtp/lib/net/smtp.rb#590
  def start(*args, helo: T.unsafe(nil), user: T.unsafe(nil), secret: T.unsafe(nil), password: T.unsafe(nil), authtype: T.unsafe(nil)); end

  # +true+ if the SMTP session has been started.
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#531
  def started?; end

  # source://net-smtp/lib/net/smtp.rb#874
  def starttls; end

  # Returns truth value if this object uses STARTTLS.
  # If this object always uses STARTTLS, returns :always.
  # If this object uses STARTTLS when the server support TLS, returns :auto.
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#365
  def starttls?; end

  # true if this object uses STARTTLS.
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#370
  def starttls_always?; end

  # true if this object uses STARTTLS when server advertises STARTTLS.
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#375
  def starttls_auto?; end

  # true if this object uses SMTP/TLS (SMTPS).
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#335
  def tls?; end

  # The hostname for verifying hostname in the server certificatate.
  #
  # source://net-smtp/lib/net/smtp.rb#264
  def tls_hostname; end

  # The hostname for verifying hostname in the server certificatate.
  #
  # source://net-smtp/lib/net/smtp.rb#264
  def tls_hostname=(_arg0); end

  # If +true+, verify th server's certificate.
  #
  # source://net-smtp/lib/net/smtp.rb#261
  def tls_verify; end

  # If +true+, verify th server's certificate.
  #
  # source://net-smtp/lib/net/smtp.rb#261
  def tls_verify=(_arg0); end

  private

  # source://net-smtp/lib/net/smtp.rb#717
  def any_require_smtputf8(addresses); end

  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#319
  def auth_capable?(type); end

  # source://net-smtp/lib/net/smtp.rb#849
  def auth_method(type); end

  # source://net-smtp/lib/net/smtp.rb#853
  def check_auth_args(user, secret, authtype = T.unsafe(nil)); end

  # source://net-smtp/lib/net/smtp.rb#843
  def check_auth_method(type); end

  # source://net-smtp/lib/net/smtp.rb#1015
  def check_continue(res); end

  # source://net-smtp/lib/net/smtp.rb#1009
  def check_response(res); end

  # source://net-smtp/lib/net/smtp.rb#999
  def critical; end

  # source://net-smtp/lib/net/smtp.rb#700
  def do_finish; end

  # source://net-smtp/lib/net/smtp.rb#688
  def do_helo(helo_domain); end

  # source://net-smtp/lib/net/smtp.rb#634
  def do_start(helo_domain, user, secret, authtype); end

  # source://net-smtp/lib/net/smtp.rb#979
  def getok(reqline); end

  # source://net-smtp/lib/net/smtp.rb#1100
  def logging(msg); end

  # source://net-smtp/lib/net/smtp.rb#683
  def new_internet_message_io(s); end

  # source://net-smtp/lib/net/smtp.rb#989
  def recv_response; end

  # source://net-smtp/lib/net/smtp.rb#709
  def requires_smtputf8(address); end

  # source://net-smtp/lib/net/smtp.rb#666
  def ssl_socket(socket, context); end

  # source://net-smtp/lib/net/smtp.rb#630
  def tcp_socket(address, port); end

  # source://net-smtp/lib/net/smtp.rb#670
  def tlsconnect(s, context); end

  # source://net-smtp/lib/net/smtp.rb#972
  def validate_line(line); end

  class << self
    # The default SMTP port number, 25.
    #
    # source://net-smtp/lib/net/smtp.rb#193
    def default_port; end

    # source://net-smtp/lib/net/smtp.rb#211
    def default_ssl_context(ssl_context_params = T.unsafe(nil)); end

    # The default SMTPS port number, 465.
    #
    # source://net-smtp/lib/net/smtp.rb#203
    def default_ssl_port; end

    # The default mail submission port number, 587.
    #
    # source://net-smtp/lib/net/smtp.rb#198
    def default_submission_port; end

    # The default SMTPS port number, 465.
    #
    # source://net-smtp/lib/net/smtp.rb#203
    def default_tls_port; end

    # :call-seq:
    #  start(address, port = nil, helo: 'localhost', user: nil, secret: nil, authtype: nil, tls: false, starttls: :auto, tls_verify: true, tls_hostname: nil, ssl_context_params: nil) { |smtp| ... }
    #  start(address, port = nil, helo = 'localhost', user = nil, secret = nil, authtype = nil) { |smtp| ... }
    #
    # Creates a new Net::SMTP object and connects to the server.
    #
    # This method is equivalent to:
    #
    #   Net::SMTP.new(address, port).start(helo: helo_domain, user: account, secret: password, authtype: authtype, tls_verify: flag, tls_hostname: hostname, ssl_context_params: nil)
    #
    # === Example
    #
    #     Net::SMTP.start('your.smtp.server') do |smtp|
    #       smtp.send_message msgstr, 'from@example.com', ['dest@example.com']
    #     end
    #
    # === Block Usage
    #
    # If called with a block, the newly-opened Net::SMTP object is yielded
    # to the block, and automatically closed when the block finishes.  If called
    # without a block, the newly-opened Net::SMTP object is returned to
    # the caller, and it is the caller's responsibility to close it when
    # finished.
    #
    # === Parameters
    #
    # +address+ is the hostname or ip address of your smtp server.
    #
    # +port+ is the port to connect to; it defaults to port 25.
    #
    # +helo+ is the _HELO_ _domain_ provided by the client to the
    # server (see overview comments); it defaults to 'localhost'.
    #
    # The remaining arguments are used for SMTP authentication, if required
    # or desired.  +user+ is the account name; +secret+ is your password
    # or other authentication token; and +authtype+ is the authentication
    # type, one of :plain, :login, or :cram_md5.  See the discussion of
    # SMTP Authentication in the overview notes.
    #
    # If +tls+ is true, enable TLS. The default is false.
    # If +starttls+ is :always, enable STARTTLS, if +:auto+, use STARTTLS when the server supports it,
    # if false, disable STARTTLS.
    #
    # If +tls_verify+ is true, verify the server's certificate. The default is true.
    # If the hostname in the server certificate is different from +address+,
    # it can be specified with +tls_hostname+.
    #
    # Additional SSLContext params can be added to +ssl_context_params+ hash argument and are passed to
    # +OpenSSL::SSL::SSLContext#set_params+
    #
    # +tls_verify: true+ is equivalent to +ssl_context_params: { verify_mode: OpenSSL::SSL::VERIFY_PEER }+.
    #
    # === Errors
    #
    # This method may raise:
    #
    # * Net::SMTPAuthenticationError
    # * Net::SMTPServerBusy
    # * Net::SMTPSyntaxError
    # * Net::SMTPFatalError
    # * Net::SMTPUnknownError
    # * Net::OpenTimeout
    # * Net::ReadTimeout
    # * IOError
    #
    # @raise [ArgumentError]
    #
    # source://net-smtp/lib/net/smtp.rb#517
    def start(address, port = T.unsafe(nil), *args, helo: T.unsafe(nil), user: T.unsafe(nil), secret: T.unsafe(nil), password: T.unsafe(nil), authtype: T.unsafe(nil), tls: T.unsafe(nil), starttls: T.unsafe(nil), tls_verify: T.unsafe(nil), tls_hostname: T.unsafe(nil), ssl_context_params: T.unsafe(nil), &block); end
  end
end

# Address with parametres for MAIL or RCPT command
#
# source://net-smtp/lib/net/smtp.rb#1105
class Net::SMTP::Address
  # :call-seq:
  #  initialize(address, parameter, ...)
  #
  # address +String+ or +Net::SMTP::Address+
  # parameter +String+ or +Hash+
  #
  # @return [Address] a new instance of Address
  #
  # source://net-smtp/lib/net/smtp.rb#1116
  def initialize(address, *args, **kw_args); end

  # mail address [String]
  #
  # source://net-smtp/lib/net/smtp.rb#1107
  def address; end

  # parameters [Array<String>]
  #
  # source://net-smtp/lib/net/smtp.rb#1109
  def parameters; end

  # source://net-smtp/lib/net/smtp.rb#1127
  def to_s; end
end

# source://net-smtp/lib/net/smtp/auth_cram_md5.rb#9
class Net::SMTP::AuthCramMD5 < ::Net::SMTP::Authenticator
  # source://net-smtp/lib/net/smtp/auth_cram_md5.rb#12
  def auth(user, secret); end

  # CRAM-MD5: [RFC2195]
  #
  # source://net-smtp/lib/net/smtp/auth_cram_md5.rb#22
  def cram_md5_response(secret, challenge); end

  # source://net-smtp/lib/net/smtp/auth_cram_md5.rb#29
  def cram_secret(secret, mask); end

  # source://net-smtp/lib/net/smtp/auth_cram_md5.rb#38
  def digest_class; end
end

# source://net-smtp/lib/net/smtp/auth_cram_md5.rb#27
Net::SMTP::AuthCramMD5::CRAM_BUFSIZE = T.let(T.unsafe(nil), Integer)

# source://net-smtp/lib/net/smtp/auth_cram_md5.rb#18
Net::SMTP::AuthCramMD5::IMASK = T.let(T.unsafe(nil), Integer)

# source://net-smtp/lib/net/smtp/auth_cram_md5.rb#19
Net::SMTP::AuthCramMD5::OMASK = T.let(T.unsafe(nil), Integer)

# source://net-smtp/lib/net/smtp/auth_login.rb#2
class Net::SMTP::AuthLogin < ::Net::SMTP::Authenticator
  # source://net-smtp/lib/net/smtp/auth_login.rb#5
  def auth(user, secret); end
end

# source://net-smtp/lib/net/smtp/auth_plain.rb#2
class Net::SMTP::AuthPlain < ::Net::SMTP::Authenticator
  # source://net-smtp/lib/net/smtp/auth_plain.rb#5
  def auth(user, secret); end
end

# source://net-smtp/lib/net/smtp/authenticator.rb#3
class Net::SMTP::Authenticator
  # @return [Authenticator] a new instance of Authenticator
  #
  # source://net-smtp/lib/net/smtp/authenticator.rb#18
  def initialize(smtp); end

  # @param str [String]
  # @return [String] Base64 encoded string
  #
  # source://net-smtp/lib/net/smtp/authenticator.rb#40
  def base64_encode(str); end

  # @param arg [String] message to server
  # @raise [res.exception_class]
  # @return [String] message from server
  #
  # source://net-smtp/lib/net/smtp/authenticator.rb#24
  def continue(arg); end

  # @param arg [String] message to server
  # @raise [SMTPAuthenticationError]
  # @return [Net::SMTP::Response] response from server
  #
  # source://net-smtp/lib/net/smtp/authenticator.rb#32
  def finish(arg); end

  # Returns the value of attribute smtp.
  #
  # source://net-smtp/lib/net/smtp/authenticator.rb#16
  def smtp; end

  class << self
    # source://net-smtp/lib/net/smtp/authenticator.rb#12
    def auth_class(type); end

    # source://net-smtp/lib/net/smtp/authenticator.rb#4
    def auth_classes; end

    # source://net-smtp/lib/net/smtp/authenticator.rb#8
    def auth_type(type); end
  end
end

# This class represents a response received by the SMTP server. Instances
# of this class are created by the SMTP class; they should not be directly
# created by the user. For more information on SMTP responses, view
# {Section 4.2 of RFC 5321}[http://tools.ietf.org/html/rfc5321#section-4.2]
#
# source://net-smtp/lib/net/smtp.rb#1025
class Net::SMTP::Response
  # Creates a new instance of the Response class and sets the status and
  # string attributes
  #
  # @return [Response] a new instance of Response
  #
  # source://net-smtp/lib/net/smtp.rb#1034
  def initialize(status, string); end

  # Returns a hash of the human readable reply text in the response if it
  # is multiple lines. It does not return the first line. The key of the
  # hash is the first word the value of the hash is an array with each word
  # thereafter being a value in the array
  #
  # source://net-smtp/lib/net/smtp.rb#1077
  def capabilities; end

  # Determines whether the response received was a Positive Intermediate
  # reply (3xx reply code)
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#1058
  def continue?; end

  # Creates a CRAM-MD5 challenge. You can view more information on CRAM-MD5
  # on Wikipedia: https://en.wikipedia.org/wiki/CRAM-MD5
  #
  # source://net-smtp/lib/net/smtp.rb#1069
  def cram_md5_challenge; end

  # Determines whether there was an error and raises the appropriate error
  # based on the reply code of the response
  #
  # source://net-smtp/lib/net/smtp.rb#1089
  def exception_class; end

  # The first line of the human readable reply text
  #
  # source://net-smtp/lib/net/smtp.rb#1063
  def message; end

  # The three digit reply code of the SMTP response
  #
  # source://net-smtp/lib/net/smtp.rb#1040
  def status; end

  # Takes the first digit of the reply code to determine the status type
  #
  # source://net-smtp/lib/net/smtp.rb#1046
  def status_type_char; end

  # The human readable reply text of the SMTP response
  #
  # source://net-smtp/lib/net/smtp.rb#1043
  def string; end

  # Determines whether the response received was a Positive Completion
  # reply (2xx reply code)
  #
  # @return [Boolean]
  #
  # source://net-smtp/lib/net/smtp.rb#1052
  def success?; end

  class << self
    # Parses the received response and separates the reply code and the human
    # readable reply text
    #
    # source://net-smtp/lib/net/smtp.rb#1028
    def parse(str); end
  end
end

# source://net-smtp/lib/net/smtp.rb#190
Net::SMTP::VERSION = T.let(T.unsafe(nil), String)

# source://net-smtp/lib/net/smtp.rb#49
class Net::SMTPAuthenticationError < ::Net::ProtoAuthError
  include ::Net::SMTPError
end

# Module mixed in to all SMTP error classes
#
# source://net-smtp/lib/net/smtp.rb#27
module Net::SMTPError
  # source://net-smtp/lib/net/smtp.rb#33
  def initialize(response, message: T.unsafe(nil)); end

  # source://net-smtp/lib/net/smtp.rb#43
  def message; end

  # This *class* is a module for backward compatibility.
  # In later release, this module becomes a class.
  #
  # source://net-smtp/lib/net/smtp.rb#31
  def response; end
end

# source://net-smtp/lib/net/smtp.rb#64
class Net::SMTPFatalError < ::Net::ProtoFatalError
  include ::Net::SMTPError
end

# source://net-smtp/lib/net/smtp.rb#54
class Net::SMTPServerBusy < ::Net::ProtoServerError
  include ::Net::SMTPError
end

# class SMTP
#
# source://net-smtp/lib/net/smtp.rb#1133
Net::SMTPSession = Net::SMTP

# source://net-smtp/lib/net/smtp.rb#59
class Net::SMTPSyntaxError < ::Net::ProtoSyntaxError
  include ::Net::SMTPError
end

# source://net-smtp/lib/net/smtp.rb#69
class Net::SMTPUnknownError < ::Net::ProtoUnknownError
  include ::Net::SMTPError
end

# source://net-smtp/lib/net/smtp.rb#74
class Net::SMTPUnsupportedCommand < ::Net::ProtocolError
  include ::Net::SMTPError
end

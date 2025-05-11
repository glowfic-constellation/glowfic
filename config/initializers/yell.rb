# rubocop:disable all
module Yell
  class Formatter
    private

    # replacing https://github.com/rsmdt/yell/blob/master/lib/yell/formatter.rb#L203
    # forcing mutable string
    def to_sprintf( table )
      buff, args, _pattern = +"", [], @pattern.dup

      while true
        match = PatternMatcher.match(_pattern)

        buff << match[1] unless match[1].empty?
        break if match[2].nil?

        buff << match[2] + 's'
        args << table[ match[3] ]

        _pattern = match[4]
      end

      %Q{sprintf("#{buff.gsub(/"/, '\"')}", #{args.join(', ')})}
    end
  end
end
# rubocop:enable all

# rubocop:disable all
class Gon
  module Base
    class << self
      private

      # replacing https://github.com/gazay/gon/blob/v6.4.0/lib/gon/base.rb#L45
      # forcing mutable string
      def formatted_data(_o)
        script = +''
        before, after = render_wrap(_o)
        script << before

        script << gon_variables(_o.global_root).
                    map { |key, val| render_variable(_o, key, val) }.join
        script << (render_watch(_o) || '')

        script << after
        script
      end
    end
  end
end
# rubocop:enable all

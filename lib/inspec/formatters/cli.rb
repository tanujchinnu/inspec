module Inspec
  module Formatters
    class CLI < Base
      RSpec::Core::Formatters.register self, :close, :dump_summary, :stop
      case RUBY_PLATFORM
      when /windows|mswin|msys|mingw|cygwin/
    
        # Most currently available Windows terminals have poor support
        # for ANSI extended colors
        COLORS = {
          'critical' => "\033[0;1;31m",
          'major'    => "\033[0;1;31m",
          'minor'    => "\033[0;36m",
          'failed'   => "\033[0;1;31m",
          'passed'   => "\033[0;1;32m",
          'skipped'  => "\033[0;37m",
          'reset'    => "\033[0m",
        }.freeze
    
        # Most currently available Windows terminals have poor support
        # for UTF-8 characters so use these boring indicators
        INDICATORS = {
          'critical' => '  [CRIT]  ',
          'major'    => '  [MAJR]  ',
          'minor'    => '  [MINR]  ',
          'failed'   => '  [FAIL]  ',
          'skipped'  => '  [SKIP]  ',
          'passed'   => '  [PASS]  ',
          'unknown'  => '  [UNKN]  ',
          'empty'    => '     ',
          'small'    => '   ',
        }.freeze
      else
        # Extended colors for everyone else
        COLORS = {
          'critical' => "\033[38;5;9m",
          'major'    => "\033[38;5;208m",
          'minor'    => "\033[0;36m",
          'failed'   => "\033[38;5;9m",
          'passed'   => "\033[38;5;41m",
          'skipped'  => "\033[38;5;247m",
          'reset'    => "\033[0m",
        }.freeze
    
        # Groovy UTF-8 characters for everyone else...
        # ...even though they probably only work on Mac
        INDICATORS = {
          'critical' => '  ×  ',
          'major'    => '  ∅  ',
          'minor'    => '  ⊚  ',
          'failed'   => '  ×  ',
          'skipped'  => '  ↺  ',
          'passed'   => '  ✔  ',
          'unknown'  => '  ?  ',
          'empty'    => '     ',
          'small'    => '   ',
        }.freeze
      end
    
      MULTI_TEST_CONTROL_SUMMARY_MAX_LEN = 60

      def close(_notification)
        puts "CLI output! woohoo!"
        puts run_data
      end
    end
  end
end

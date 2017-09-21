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
        output.puts ""

        run_data[:profiles].each do |profile|
          print_profile_header(profile)
          print_standard_control_results(profile)
          print_anonymous_control_results(profile)
        end

        print_profile_summary
        print_tests_summary
      end

      private

      def print_profile_header(profile)
        output.puts "Profile: #{format_profile_name(profile)}"
        output.puts "Version: #{profile[:version] || '(not specified)'}"
        output.puts "Target: #{format_target}" unless format_target.nil?
        output.puts ""
      end

      def print_standard_control_results(profile)
        standard_controls_from_profile(profile).each do |control|
          output.puts format_control_header(control)
          control[:results].each do |result|
            output.puts format_result(result)
          end
          # print_line(
          #   color:      control.summary_indicator,
          #   indicator:  INDICATORS[control.summary_indicator] || INDICATORS['unknown'],
          #   summary:    format_lines(control.summary, INDICATORS['empty']),
          #   id:         "#{control.id}: ",
          #   profile:    control.profile_id,
          # )      
        end
      end

      def print_anonymous_control_results(profile)
        anonymous_controls_from_profile(profile).each do |control|
        end
      end

      def format_profile_name(profile)
        if profile[:title].nil?
          "#{profile[:name] || 'unknown'}"
        else
          "#{profile[:title]} (#{profile[:name] || 'unknown'})"
        end
      end

      def format_target
        return if @backend.nil?

        connection = @backend.backend
        connection.respond_to?(:uri) ? connection.uri : nil
      end

      def format_control_header(control)
        " [INDICATOR] #{control[:id]}: #{control[:title]} ([CONTROL SUMMARY])"
      end

      def format_result(result)
      end

      def print_profile_summary
        summary = profile_summary
        return unless summary['total'] > 0
    
        success_str = summary['passed'] == 1 ? '1 successful control' : "#{summary['passed']} successful controls"
        failed_str  = summary['failed']['total'] == 1 ? '1 control failure' : "#{summary['failed']['total']} control failures"
        skipped_str = summary['skipped'] == 1 ? '1 control skipped' : "#{summary['skipped']} controls skipped"
    
        success_color = summary['passed'] > 0 ? 'passed' : 'no_color'
        failed_color = summary['failed']['total'] > 0 ? 'failed' : 'no_color'
        skipped_color = summary['skipped'] > 0 ? 'skipped' : 'no_color'
    
        s = format('Profile Summary: %s, %s, %s',
                   format_with_color(success_color, success_str),
                   format_with_color(failed_color, failed_str),
                   format_with_color(skipped_color, skipped_str),
                  )
        output.puts(s) if summary['total'] > 0
      end

      def print_tests_summary
        summary = tests_summary
    
        failed_str = summary['failed'] == 1 ? '1 failure' : "#{summary['failed']} failures"
    
        success_color = summary['passed'] > 0 ? 'passed' : 'no_color'
        failed_color = summary['failed'] > 0 ? 'failed' : 'no_color'
        skipped_color = summary['skipped'] > 0 ? 'skipped' : 'no_color'
    
        s = format('Test Summary: %s, %s, %s',
                   format_with_color(success_color, "#{summary['passed']} successful"),
                   format_with_color(failed_color, failed_str),
                   format_with_color(skipped_color, "#{summary['skipped']} skipped"),
                  )
    
        output.puts(s)
      end


      def format_with_color(color_name, text)
        return text unless RSpec.configuration.color
        return text unless COLORS.key?(color_name)
    
        "#{COLORS[color_name]}#{text}#{COLORS['reset']}"
      end

      def standard_controls_from_profile(profile)
        profile[:controls].select { |c| !is_anonymous_control?(c) }
      end

      def anonymous_controls_from_profile(profile)
        profile[:controls].select { |c| is_anonymous_control?(c) }
      end

      def is_anonymous_control?(control)
        control[:id].start_with?('(generated from ')
      end

      def control_status(control)
      end
    end
  end
end

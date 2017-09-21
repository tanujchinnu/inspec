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
          'critical' => '[CRIT]',
          'major'    => '[MAJR]',
          'minor'    => '[MINR]',
          'failed'   => '[FAIL]',
          'skipped'  => '[SKIP]',
          'passed'   => '[PASS]',
          'unknown'  => '[UNKN]',
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
          'critical' => '×',
          'major'    => '∅',
          'minor'    => '⊚',
          'failed'   => '×',
          'skipped'  => '↺',
          'passed'   => '✔',
          'unknown'  => '?',
        }.freeze
      end
    
      MULTI_TEST_CONTROL_SUMMARY_MAX_LEN = 60

      def close(_notification)
        run_data[:profiles].each do |profile|
          output.puts ''          
          print_profile_header(profile)
          print_standard_control_results(profile)
          print_anonymous_control_results(profile)
        end

        output.puts ''
        print_profile_summary
        print_tests_summary
      end

      private

      def print_profile_header(profile)
        output.puts "Profile: #{format_profile_name(profile)}"
        output.puts "Version: #{profile[:version] || '(not specified)'}"
        output.puts "Target: #{format_target}" unless format_target.nil?
        output.puts ''
      end

      def print_standard_control_results(profile)
        standard_controls_from_profile(profile).each do |control_from_profile|
          control = Control.new(control_from_profile)
          output.puts format_control_header(control)
          control.results.each do |result|
            output.puts format_result(control, result, :standard)
          end
        end
      end

      def print_anonymous_control_results(profile)
        anonymous_controls_from_profile(profile).each do |control_from_profile|
          control = Control.new(control_from_profile)
          output.puts format_control_header(control)
          control.results.each do |result|
            output.puts format_result(control, result, :anonymous)
          end
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
        impact = control.impact_string
        format_message(
          color: impact,
          indicator: impact,
          message: control.title_for_report
        )
      end

      def format_result(control, result, type)
        impact = control.impact_string_for_result(result)

        message = if result[:status] == 'skipped'
                    result[:skip_message]
                  elsif type == :anonymous
                    result[:expectation_message]
                  else
                    result[:code_desc]
                  end

        # append any failure details to the message if they exist
        message += "\n#{result[:message]}" if result[:message]
        
        format_message(
          color: impact,
          indicator: impact,
          indentation: 5,
          message: message,
        )
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
        profile[:controls].select { |c| is_anonymous_control?(c) && !c[:results].nil? }
      end

      def is_anonymous_control?(control)
        control[:id].start_with?('(generated from ')
      end

      def format_message(message_info)
        indicator = message_info[:indicator]
        color = message_info[:color]
        indentation = message_info.fetch(:indentation, 2)
        message = message_info[:message]

        message_to_format = ""
        message_to_format += "#{INDICATORS[indicator]}  " unless indicator.nil?
        message_to_format += message.to_s

        format_with_color(color, indent_lines(message_to_format, indentation))
      end

      def indent_lines(message, indentation)
        message.lines.map { |line| " " * indentation + line }.join
      end

      class Control
        IMPACT_SCORES = {
          critical: 0.7,
          major: 0.4,
        }
  
        attr_reader :data

        def initialize(control_hash)
          @data = control_hash
        end

        def id
          data[:id]
        end
        
        def title
          data[:title]
        end

        def results
          data[:results]
        end

        def impact
          data[:impact]
        end

        def anonymous?
          id.start_with?('(generated from ')
        end

        def title_for_report
          # if this is an anonymous control, just grab the resource title from any result entry
          return results.first[:resource_title] if anonymous?

          title_for_report = "#{id}: #{title}"

          # we will not add any additional data to the title if there's only
          # zero or one test for this control.
          return title_for_report if results.size <= 1

          # append a failure summary if appropriate. Only do so if there is more than
          # one failure.
          title_for_report += " (#{failure_count} failed)" if failure_count > 1

          title_for_report
        end

        def impact_string
          if anonymous?
            nil
          elsif impact.nil?
            'unknown'
          elsif results.all? { |r| r[:status] == 'skipped' }
            'skipped'
          elsif results.all? { |r| r[:status] == 'passed' } || results.empty?
            'passed'
          elsif impact >= IMPACT_SCORES[:critical]
            'critical'
          elsif impact >= IMPACT_SCORES[:major]
            'major'
          else
            'minor'
          end
        end

        def impact_string_for_result(result)
          if results.all? { |r| r[:status] == 'skipped' }
            'skipped'
          elsif result[:status] == 'passed'
            'passed'
          elsif impact.nil?
            'unknown'
          elsif impact >= IMPACT_SCORES[:critical]
            'critical'
          elsif impact >= IMPACT_SCORES[:major]
            'major'
          else
            'minor'
          end
        end

        def failure_count
          results.select { |r| r[:status] == 'failed' }.size
        end
      end
    end
  end
end

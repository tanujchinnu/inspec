require 'json'

module Inspec
  module Formatters
    class JsonMin < Base
      RSpec::Core::Formatters.register self, :close, :dump_summary, :stop
      
      def close(_notification)
        report = {
          version: run_data[:version],
          controls: [],
          statistics: { duration: run_data[:statistics][:duration] },
        }

        # collect all test results and add them to the report
        run_data[:profiles].each do |profile|
          profile_id = profile[:name]
          profile[:controls].each do |control|
            control_id = control[:id]
            control[:results].each do |result|
              result_for_report = {
                id: control_id,
                profile_id: profile_id,
                status: result[:status],
                code_desc: result[:code_desc],
              }

              result_for_report[:message] = result[:message] if result.key?(:message)

              report[:controls] << result_for_report
            end
          end
        end

        output.write report.to_json
      end
    end
  end
end

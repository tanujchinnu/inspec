require 'json'

module Inspec
  module Formatters
    class Json < Base
      RSpec::Core::Formatters.register self, :close, :dump_summary, :stop
      
      def close(_notification)
        output.write run_data.to_json
      end
    end
  end
end

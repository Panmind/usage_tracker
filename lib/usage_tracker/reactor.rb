require 'usage_tracker'
require 'json'

module UsageTracker
  module Reactor
    # This method is called upon every data reception
    #
    def receive_data(data)
      doc = parse(data)
      if doc && check(doc)
        store(doc)
      end
    end

    # Debug hook
    if UsageTracker.env == 'test'
      alias :real_receive_data :receive_data
      def receive_data(data)
        UsageTracker.log.debug "Received #{data.inspect}"
        ret = real_receive_data(data)
        UsageTracker.log.debug ret ? "Stored #{ret}" : 'Failed to store input data'
      end
    end

    private
      def parse(data)
        JSON(data).tap {|h| h.reject! {|k,v| v.nil?}}
      rescue JSON::ParserError
        UsageTracker.log.error "Tossing out invalid JSON #{data.inspect} (#{$!.message.inspect})"
        return nil
      end

      def check(doc)
        error =
          if    !doc.kind_of?(Hash) then 'invalid'
          elsif doc.empty?          then 'empty'
          elsif !(missing = check_keys(doc)).empty?
            "#{missing.join(', ')} missing"
          end

        if error
          UsageTracker.log.error "Tossing out invalid document #{doc.inspect}: #{error}"
          return nil
        else
          return true
        end
      end

      def check_keys(doc)
        %w( duration env status ).reject {|k| doc.has_key?(k)}
      end

      def store(doc)
        tries = 0

        begin
          doc['_id'] = make_id
          UsageTracker.adapter.save_doc(doc)

        rescue RestClient::Conflict => e
          if (tries += 1) < 10
            UsageTracker.log.warn "Retrying to save #{doc.inspect}, try #{tries}"
            retry
          else
            UsageTracker.log.error "Losing '#{doc.inspect}' because of too many conflicts"
          end

        rescue Encoding::UndefinedConversionError
          UsageTracker.log.error "Losing '#{doc.inspect}' because #$!" # FIXME handle this error properly
        end
      end

      # Timestamp as _id has the advantage that documents
      # are sorted automatically by CouchDB.
      #
      # Eventual duplication (multiple servers) is (possibly)
      # avoided by adding a random digit at the end.
      #
      def make_id
        Time.now.to_f.to_s.ljust(16, '0') + rand(10).to_s
      end
  end

end

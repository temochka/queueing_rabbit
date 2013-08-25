module QueueingRabbit

  module JobExtensions

    module Retryable

      def retries
        headers['qr_retries'].to_i
      end

      def retry_upto(max_retries)
        if retries < max_retries
          updated_headers = headers.update('qr_retries' => retries + 1)
          self.class.enqueue(payload, :headers => updated_headers)
        end
      end

    end

  end

end
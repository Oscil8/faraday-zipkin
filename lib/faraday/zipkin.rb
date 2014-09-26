require 'faraday'
require 'finagle-thrift'
require 'finagle-thrift/trace'
require 'uri'

require 'faraday/zipkin/version'

module Faraday
  module Zipkin
    class TraceHeaders < ::Faraday::Middleware
      B3_HEADERS = {
        :trace_id => "X-B3-TraceId",
        :parent_id => "X-B3-ParentSpanId",
        :span_id => "X-B3-SpanId",
        :sampled => "X-B3-Sampled"
      }.freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        trace_id = ::Trace.id

        # handle either a URI object (passed by Faraday v0.8.x in testing), or something string-izable
        host = env[:url].respond_to?(:host) ? env[:url].host : URI.parse(env[:url].to_s).host

        ::Trace.push(trace_id.next_id) do
          ::Trace.record(::Trace::Annotation.new(::Trace::Annotation::CLIENT_SEND, host))
          B3_HEADERS.each do |method, header|
            env[:request_headers][header] = ::Trace.id.send(method).to_s
          end
          result = @app.call(env)
          ::Trace.record(::Trace::Annotation.new(::Trace::Annotation::CLIENT_RECV, host))
          result
        end
      end
    end
  end
end

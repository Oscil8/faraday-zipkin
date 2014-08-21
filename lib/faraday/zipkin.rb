require 'faraday'
require 'finagle-thrift'
require 'finagle-thrift/trace'

require "faraday/zipkin/version"

module Faraday
  module Zipkin
    class TraceHeaders < ::Faraday::Middleware
      B3_HEADERS = {
        :trace_id => "X-B3-TraceId",
        :parent_id => "X-B3-ParentSpanId",
        :span_id => "X-B3-SpanId",
        :sampled => "X-B3-Sampled",
        :flags => "X-B3-Flags"
      }.freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        trace_id = ::Trace.id
        B3_HEADERS.each do |method, header|
          env[:request_headers][header] = trace_id.send(method).to_s
        end
        @app.call(env)
      end
    end
  end
end

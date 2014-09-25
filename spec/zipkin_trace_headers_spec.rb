describe Faraday::Zipkin::TraceHeaders do
  let(:middleware) { described_class.new(lambda{|env| env}) }

  def process(body, headers={})
    env = {
      :body => body,
      :request_headers => Faraday::Utils::Headers.new(headers),
    }
    middleware.call(env)
  end

  context 'request' do
    context 'with tracing id' do
      let(:trace_id) { ::Trace::TraceId.new(1, 2, 3, true) }

      it 'sets the X-B3 request headers' do
        result = nil
        ::Trace.push(trace_id) do
          result = process('')
        end
        expect(result[:request_headers]['X-B3-TraceId']).to eq('0000000000000001')
        expect(result[:request_headers]['X-B3-ParentSpanId']).to eq('0000000000000002')
        expect(result[:request_headers]['X-B3-SpanId']).to eq('0000000000000003')
        expect(result[:request_headers]['X-B3-Sampled']).to eq('true')
      end
    end
  end
end

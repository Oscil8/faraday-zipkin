describe Faraday::Zipkin::TraceHeaders do
  let(:middleware) { described_class.new(lambda{|env| env}) }
  let(:hostname) { 'service.example.com' }

  def process(body, url, headers={})
    env = {
      :url => url,
      :body => body,
      :request_headers => Faraday::Utils::Headers.new(headers),
    }
    middleware.call(env)
  end

  # custom matcher for trace annotation
  RSpec::Matchers.define :have_value_and_host do |v, h|
    match { |actual| actual.value == v && actual.host == h }
  end

  shared_examples 'can make requests' do
    context 'with tracing id' do
      let(:trace_id) { ::Trace::TraceId.new(1, 2, 3, true) }

      it 'sets the X-B3 request headers' do
        # expect SEND then RECV
        expect(::Trace).to receive(:record).with(have_value_and_host(::Trace::Annotation::CLIENT_SEND, hostname)).ordered
        expect(::Trace).to receive(:record).with(have_value_and_host(::Trace::Annotation::CLIENT_RECV, hostname)).ordered

        result = nil
        ::Trace.push(trace_id) do
          result = process('', url)
        end
        expect(result[:request_headers]['X-B3-TraceId']).to eq('0000000000000001')
        expect(result[:request_headers]['X-B3-ParentSpanId']).to eq('0000000000000003')
        expect(result[:request_headers]['X-B3-SpanId']).not_to eq('0000000000000003')
        expect(result[:request_headers]['X-B3-SpanId']).to match(/^\h{16}$/)
        expect(result[:request_headers]['X-B3-Sampled']).to eq('true')
      end
    end

    context 'without tracing id' do
      it 'generates a new ID, and sets the X-B3 request headers' do
        result = process('', url)
        expect(result[:request_headers]['X-B3-TraceId']).to match(/^\h{16}$/)
        expect(result[:request_headers]['X-B3-ParentSpanId']).to match(/^\h{16}$/)
        expect(result[:request_headers]['X-B3-SpanId']).to match(/^\h{16}$/)
        expect(result[:request_headers]['X-B3-Sampled']).to match(/(true|false)/)
      end
    end
  end

  context 'request with string URL' do
    let(:url) { "https://#{hostname}/some/path/here" }

    include_examples 'can make requests'
  end

  # in testing, Faraday v0.8.x passes a URI object rather than a string
  context 'request with pre-parsed URL' do
    let(:url) { URI.parse("https://#{hostname}/some/path/here") }

    include_examples 'can make requests'
  end
end

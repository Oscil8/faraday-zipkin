describe Faraday::Zipkin::TraceHeaders do
  let(:wrapped_app) { lambda{|env| env} }

  let(:hostname) { 'service.example.com' }
  let(:host_ip) { 0x11223344 }

  def process(body, url, headers={})
    env = {
      :url => url,
      :body => body,
      :request_headers => Faraday::Utils::Headers.new(headers),
    }
    middleware.call(env)
  end

  # custom matchers for trace annotation
  RSpec::Matchers.define :have_value do |v|
    match { |actual| actual.value == v }
  end

  RSpec::Matchers.define :have_endpoint do |ip, svc|
    match { |actual| actual.host.kind_of?(::Trace::Endpoint) &&
                     actual.host.ipv4 == ip &&
                     actual.host.service_name == svc }
  end

  before(:each) {
    allow(::Trace::Endpoint).to receive(:host_to_i32).with(hostname).and_return(host_ip)
  }

  shared_examples 'can make requests' do
    context 'with tracing id' do
      let(:trace_id) { ::Trace::TraceId.new(1, 2, 3, true) }

      it 'sets the X-B3 request headers' do
        # expect SEND then RECV
        expect(::Trace).to receive(:record).with(have_value(::Trace::Annotation::CLIENT_SEND).and(have_endpoint(host_ip, service_name))).ordered
        expect(::Trace).to receive(:record).with(have_value(::Trace::Annotation::CLIENT_RECV).and(have_endpoint(host_ip, service_name))).ordered

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

  context 'middleware configured (without service_name)' do
    let(:middleware) { described_class.new(wrapped_app) }
    let(:service_name) { 'service' }

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

  context 'configured with service_name "foo"' do
    let(:middleware) { described_class.new(wrapped_app, 'foo') }
    let(:service_name) { 'foo' }

    # in testing, Faraday v0.8.x passes a URI object rather than a string
    context 'request with pre-parsed URL' do
      let(:url) { URI.parse("https://#{hostname}/some/path/here") }

      include_examples 'can make requests'
    end
  end
end

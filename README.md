# Faraday::Zipkin

Faraday middleware to generate Zipkin tracing headers.

Note that you should also be using the zipkin-tracer Rack middleware
to generate trace IDs around your requests:
https://github.com/twitter/zipkin/tree/master/zipkin-gems/zipkin-tracer

Zipkin tracing headers are documented at
https://github.com/twitter/zipkin/blob/master/doc/collector-api.md
 
## Usage

Include Faraday::Zipkin::TraceHeaders as a Faraday middleware:

    require 'faraday'
    require 'faraday/zipkin'
    
    conn = Faraday.new(:url => 'http://localhost:9292/') do |faraday|
      faraday.use Faraday::Zipkin::TraceHeaders
      # default Faraday stack
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
    end
 
## Contributing

1. Fork it ( https://github.com/[my-github-username]/faraday-zipkin/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

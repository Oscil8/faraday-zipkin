# Faraday::Zipkin

![TravisCI Build status](https://travis-ci.org/Oscil8/faraday-zipkin.svg?branch=master)

Faraday middleware to generate Zipkin tracing headers.

For more information about Zipkin, go to
http://twitter.github.io/zipkin
http://github.com/twitter/zipkin

This gem implements the client side described at
http://twitter.github.io/zipkin/instrument.html

Note that you should also be using the zipkin-tracer Rack middleware
to generate trace IDs around your requests:
https://github.com/twitter/zipkin/tree/master/zipkin-gems/zipkin-tracer

Zipkin tracing headers for HTTP APIs are documented at
https://github.com/twitter/zipkin/blob/master/doc/collector-api.md

## Usage

Include Faraday::Zipkin::TraceHeaders as a Faraday middleware:

    require 'faraday'
    require 'faraday/zipkin'
    
    conn = Faraday.new(:url => 'http://localhost:9292/') do |faraday|
      faraday.use Faraday::Zipkin::TraceHeaders [, 'service_name']
      # default Faraday stack
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
    end

Note that supplying the service name for the destination service is
optional; the tracing will default to a service name derived from the
first section of the destination URL (e.g. 'service.example.com' =>
'service').

## Contributing

1. Fork it ( https://github.com/Oscil8/faraday-zipkin/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

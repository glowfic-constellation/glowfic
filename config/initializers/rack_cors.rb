## Configure Rack CORS Middleware, so that CloudFront can serve our assets.
## See https://github.com/cyu/rack-cors or
## http://stackoverflow.com/questions/32592571/cloudfront-cors-issue-serving-fonts-on-rails-application

if defined? Rack::Cors
    Rails.configuration.middleware.insert_before 0, Rack::Cors do
        allow do
            origins %w[
                https://vast-journey-9935.herokuapp.com
                 http://vast-journey-9935.herokuapp.com
                https://www.glowfic.com
                 http://www.glowfic.com
                https://glowfic.com
                 http://glowfic.com
            ]
            resource '/assets/*'
            resource '/images/*'
        end
    end
end

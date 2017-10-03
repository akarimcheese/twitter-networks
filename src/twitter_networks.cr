require "./twitter_networks/*"
require "crystweet"

module TwitterNetworks
    class Network
        def initialize(twitter_consumer_key, twitter_consumer_secret, twitter_access_token, twitter_access_secret)
            # @client = Twitter::Rest::Client.new(
            #     ENV["TWITTER_CONSUMER_KEY"], 
            #     ENV["TWITTER_CONSUMER_SECRET"], 
            #     ENV["TWITTER_ACCESS_TOKEN"],
            #     ENV["TWITTER_ACCESS_SECRET"]
            # ).persistent
            @client = Twitter::Rest::Client.new(
                twitter_consumer_key,
                twitter_consumer_secret,
                twitter_access_token,
                twitter_access_secret
            ).persistent
        end
    end
    client = 
end

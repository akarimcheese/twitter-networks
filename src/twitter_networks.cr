require "./twitter_networks/*"
require "crystweet"

module TwitterNetworks
    class Network
        property rest_client : Twitter::Rest::Client
        property graph : Hash(String, Array(String))
        
        def initialize(twitter_consumer_key, twitter_consumer_secret, twitter_access_token, twitter_access_secret)
            on_rate_limit = ->{ puts "Rate limit reached. Sleeping for 15 minutes..." }
            @rest_client = Twitter::Rest::Client.new(
                twitter_consumer_key,
                twitter_consumer_secret,
                twitter_access_token,
                twitter_access_secret
            ).persistent(on_rate_limit)
            
            # Follower => Followed
            @graph = {} of String => Array(String)
        end
        
        def on_rate_limit(&block)
            @rest_client.persistent(block)
            self
        end
        
        def on_relationship_found(&block : String, String -> Void)
            @on_relationship_found_callback = block
            self
        end
        
        def add_user(screen_name)
            following = @graph.keys.select { |target_screen_name|
                relationship_request = @rest_client.relationship(screen_name, target_screen_name)
                
                relationship = relationship_request.show()
                
                if relationship.source.followed_by
                    if callback = @on_relationship_found_callback
                        callback.call(target_screen_name, screen_name)
                    end
                    @graph[target_screen_name] << screen_name
                end
                
                if relationship.source.following && (callback = @on_relationship_found_callback)
                    callback.call(screen_name, target_screen_name)
                end
                relationship.source.following
            }
            
            @graph[screen_name] = following
        end
        
        def add_users(screen_names)
            screen_names.each do |screen_name|
                add_user(screen_name)
            end
        end
        
        def each_edge
            @graph.keys.each { |follower|
                @graph[follower].each { |followed|
                    yield follower, followed
                }
            }
        end
        
        def edges : Array(Edge)
            edges = [] of Edge
            
            each_edge { |follower, followed|
                edges << Edge.new(follower, followed)
            }
            
            edges
        end
        
        def to_csv_string
            # TODO: use an actual string builder
            string_builder = ""
            
            each_edge { |follower, followed|
                string_builder = string_builder + "#{follower}, #{followed}\n"
            }
            
            if string_builder != ""
                string_builder = string_builder.rchop
            end
            
            string_builder
        end
    end
    
    struct Edge
        property source : String
        property target : String
        
        def initialize(@source : String, @target : String)
        end
        
        def [](index : Int)
            case index
            when 0
                @source
            when 1
                @target
            else
                raise IndexError.new
            end
        end
        
        def to_s
            "#{source}, #{target}"
        end
    end
    
    # network = Network.new(
    #     ENV["TWITTER_CONSUMER_KEY"], 
    #     ENV["TWITTER_CONSUMER_SECRET"], 
    #     ENV["TWITTER_ACCESS_TOKEN"],
    #     ENV["TWITTER_ACCESS_SECRET"]
    # )
    
    # network.add_users(["JODYHiGHROLLER", "KimKardashian", "BarackObama", "BillGates"])
    
    # puts network.graph.inspect
    
    # network.on_rate_limit {
    #     puts "Twitter Rate Limit reached. Sleeping for 5 minutes..."
    # }
    
    # network.on_relationship_found { |follower, followed|
    #   puts "Twitter Networks has found that #{follower} follows #{followed}!"
    # }
    
    # network.add_user("JohnCena")
    
    # puts network.graph.inspect
    
    # network_csv = network.to_csv_string

    # File.write("network.csv", network_csv)
end

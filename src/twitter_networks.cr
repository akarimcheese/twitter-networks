require "./twitter_networks/*"
require "crystweet"

module Twitter
    class Network
        property rest_client : Twitter::Rest::Client
        property stream_client : Twitter::Stream::Client
        property graph : Hash(String, Array(String))
        
        def initialize(twitter_consumer_key, twitter_consumer_secret, twitter_access_token, twitter_access_secret)
            on_rate_limit = ->{ puts "Rate limit reached. Sleeping for 15 minutes..." }
            @rest_client = Twitter::Rest::Client.new(
                twitter_consumer_key,
                twitter_consumer_secret,
                twitter_access_token,
                twitter_access_secret
            ).persistent(on_rate_limit)
            
            @stream_client = Twitter::Stream::Client.new(
                twitter_consumer_key,
                twitter_consumer_secret,
                twitter_access_token,
                twitter_access_secret
            ).include(:retweet, :quote, :reply)
            
            # Follower => Followed
            @graph = {} of String => Array(String)
            # Followed => Follower
            @reverse_graph = {} of String => Array(String)
            
            # TODO: Change to user data table, to store all Twitter data for user
            # not just the id
            @user_id_table = {} of String => UInt64
            
            @lock = Mutex.new
        end
        
        def on_rate_limit(&block)
            @rest_client.persistent(block)
            self
        end
        
        def on_relationship_found(&block : String, String -> Void)
            @on_relationship_found_callback = block
            self
        end
        
        def on_user_added(&block : Twitter::Response::User -> Void)
            @on_user_added_callback = block
            self
        end
        
        def add_user(screen_name)
            following = [] of String
            followers = [] of String
            
            # TODO: Check if user exists. Call error callback if not.
            user = @rest_client.user(screen_name).show()
            @user_id_table[screen_name] = user.id
            
            if callback = @on_user_added_callback
                callback.call(user)
            end
            
            @lock.lock
            @graph.keys.each { |target_screen_name|
                relationship_request = @rest_client.relationship(screen_name, target_screen_name)
                
                relationship = relationship_request.show()
                
                if relationship.source.followed_by
                    if callback = @on_relationship_found_callback
                        callback.call(target_screen_name, screen_name)
                    end
                    @graph[target_screen_name] << screen_name
                    followers << target_screen_name
                end
                
                if relationship.source.following 
                    @reverse_graph[target_screen_name] << screen_name
                    following << target_screen_name
                    
                    if callback = @on_relationship_found_callback
                        callback.call(screen_name, target_screen_name)
                    end
                end
                relationship.source.following
            }
            
            @graph[screen_name] = following
            @reverse_graph[screen_name] = followers
            @lock.unlock
        end
        
        def add_users(screen_names)
            screen_names.each do |screen_name|
                add_user(screen_name)
            end
        end
        
        def each_node
            @user_id_table.keys.each { |node|
                yield node
            }
        end
        
        def nodes
            @user_id_table.keys
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
        
        def stream_from_network
            user_ids = @user_id_table.values
            
            @stream_client.stream(follow: user_ids) { |tweet|
                if tweet_from_network(tweet)
                    yield tweet
                end
            }
        end
        
        def tweet_from_network(tweet : Twitter::Response::Tweet)
            @user_id_table.has_key?(tweet.user.screen_name)
        end
        
        def indegree(screen_name)
            @reverse_graph[screen_name].size
        end
        
        def outdegree(screen_name)
            @graph[screen_name].size
        end
        
        def indegree_centrality(screen_name)
            @reverse_graph[screen_name].size.to_f / (nodes.size - 1)
        end
        
        def outdegree_centrality(screen_name)
            @graph[screen_name].size.to_f / (nodes.size - 1)
        end
        
        def has_edge?(source, target)
            return @graph[source].includes?(target)
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
end

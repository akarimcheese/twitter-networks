# twitter_networks

A library for tools to create Twitter Networks in Crystal. In progress. 

Feel free to contribute with any features you see fit! I'm looking to 
add some community detection algos and stuff.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  twitter_networks:
    github: akarimcheese/twitter_networks
```

## Usage

```crystal
require "twitter_networks"
```

Creating a Network Instance

```crystal
network = Network.new(
  ENV["TWITTER_CONSUMER_KEY"], 
  ENV["TWITTER_CONSUMER_SECRET"], 
  ENV["TWITTER_ACCESS_TOKEN"],
  ENV["TWITTER_ACCESS_SECRET"]
)
```

Add users to network

```crystal
network.add_users(["JODYHiGHROLLER", "KimKardashian", "BarackObama", "BillGates"])

puts network.graph.inspect
# {"JODYHiGHROLLER" => ["KimKardashian", "BarackObama", "BillGates"], "KimKardashian" => ["BarackObama"], "BarackObama" => [], "BillGates" => ["BarackObama"]}
```

Print a message when Twitter rate limits occur

```crystal
network.on_rate_limit {
  puts "Twitter Rate Limit reached. Sleeping for 5 minutes..."
}
```

Print a message as a follower-followed relationship is found in `add_user()`/`add_users()`

```crystal
network.on_relationship_found { |follower, followed|
  puts "Twitter Networks has found that #{follower} follows #{followed}!"
}

network.add_user("JohnCena")
# Twitter Networks has found that JODYHiGHROLLER follows JohnCena!
# Twitter Networks has found that JohnCena follows KimKardashian!
# Twitter Networks has found that JohnCena follows BarackObama!
# Twitter Networks has found that JohnCena follows BillGates!
```

Get the network as a csv string

```crystal
network_csv = network.to_csv_string

File.write("network.csv", network_csv)
```



## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/akarimcheese/twitter_networks/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [akarimcheese](https://github.com/akarimcheese) Ayman Karim - creator, maintainer

# Arke

Arke is a trading bot platform

## Exchange Lists

| NAME | TARGET | SOURCE | WEBSOCKET|
|:---:|:---:|:---:|:---:|
| BitUBU     |![GREEN](https://via.placeholder.com/15/008000/?text=+)|![GREEN](https://via.placeholder.com/15/008000/?text=+)|![GREEN](https://via.placeholder.com/15/008000/?text=+)|  
| Binance     |![RED](https://via.placeholder.com/15/f03c15/?text=+)|![GREEN](https://via.placeholder.com/15/008000/?text=+)|![GREEN](https://via.placeholder.com/15/008000/?text=+)|
| Bitfinex     |![RED](https://via.placeholder.com/15/f03c15/?text=+)|![GREEN](https://via.placeholder.com/15/008000/?text=+)|![GREEN](https://via.placeholder.com/15/008000/?text=+)|
| Latoken     |![GREEN](https://via.placeholder.com/15/008000/?text=+)|![RED](https://via.placeholder.com/15/f03c15/?text=+)|![RED](https://via.placeholder.com/15/f03c15/?text=+)| 
| Cointiger     |![GREEN](https://via.placeholder.com/15/008000/?text=+)|![RED](https://via.placeholder.com/15/f03c15/?text=+)|![RED](https://via.placeholder.com/15/f03c15/?text=+)| 
| Azbit     |![GREEN](https://via.placeholder.com/15/f03c15/?text=+)|![RED](https://via.placeholder.com/15/f03c15/?text=+)|![RED](https://via.placeholder.com/15/f03c15/?text=+)| 

## Development

### Setup

To start local development:

1. Clone the repo:
   ```shell
   git clone git@github.com/bitubu/mmbot.git
   ```
2. Install dependencies
   ```shell
   bundle install
   ```

Now you can run Arke using `bin/arke` command.

### Example usage

Arke is a liquidity aggregation tool which supports copy strategy

dd platform host and credentials to `config/strategy.yaml`

```yaml
strategy:
  type: 'copy'
  market: 'ETHUSD'
  targets:
    - driver: bitubu
      host: "https://api.bitubu.com"
      name: John
      key: "xxxxxxxxxx"
      secret: "xxxxxxxxxx"
  sources:
    - driver: source1
      host: "http://www.example2.com"
      name: Joe
      key: "xxxxxxxxxxx"
      secret: "xxxxxxxxxxxx"
    - driver: source2
      host: "http://www.example2.com"
      name: Joe
      key: "xxxxxxxxxxx"
      secret: "xxxxxxxxxxxx"
```

To open development console, use `bin/arke console`

Now your configuration variables can be reached with
```ruby
Arke::Configuration.get(:variable_name)
# or
Arke::Configuration.require!(:variable_name)

# For example, to get target host:
Arke::Configuration.require!(:target)['host']

#For api key:
Arke::Configuration.require!(:target)['key']
Arke::Configuration.require!(:target)['secret']
```

To start trading bot type

```shell
bin/arke start
```

cd markets
```
bundle exec ./btcusdt.sh
```

cd mmbot
```
bundle exec bin/arke start btcusdt
```


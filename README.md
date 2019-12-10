## Coinbase Pro - Q Client 
An interactive trading and market data client.
Simple to use, and easy to install, the client provides seamless integration between trade execution, order management, and data analysis.  
### Benefits
- Intuitive q/kdb wrapper for both public and  authenticated endpoints.
- No handling of nuanced API calls or working with cumbersome libraries, the client provides full abstraction for every API endpoint.
	- Easy to use functions, conventional q execution and access.
	- Auto pagination of API results, converts and casts into native q datatypes.
    - Extension methods for more complex order types (stop loss, stop entry).

## Requirements
- Linux
- Anaconda Python >= 3.5

## Getting Started
#### Install the client
```bash
❯ git clone https://github.com/michaelsimonelli/qoinbase-q.git
```
#### Create and activate the conda environment
```bash
❯ cd qoinbase-q
❯ conda env create -f environment.yml
❯ conda activate cbpro
```
#### Start the qoinbase-q session
```bash
❯ ./start -p 5000
```
> **NOTE**: If you receive a 'k4.lic error, you'll need to copy an authorized license file into the conda environment's QHOME dir. If you don't have an authorized license, simply start q normally and you'll be prompted with the license agreement.

If the client was launched successfully, you should see an output like this:
```bash
2019.09.02T17:06:59.677 [Py] Imported module 'builtins'
2019.09.02T17:06:59.677 [Py] Mapped functions (builtins; list, next, vars, str) in `.py context
2019.09.02T17:06:59.809 [Py] Imported module 'cbpro'
2019.09.02T17:06:59.898 [Py] Reflected module 'cbpro' to `cbpro context
```

**Initialize API**
>.api.init
 - typ - type of client to
	 - public
	 - auth
 - lib - api library
	 - mkt (market data)
	 - ord (account and order mgmt)
 - env - endpoint environment
	 - live
	 - test (sandbox)

## Clients
The q-client works out of the box with out any further configuration.
However, only the implementations mapped directly from python are available after start up.
The advanced, wrapped clients will be covered in a later section.

When a client is initialized, it has to be *instantiated* into a q variable. The q variable is stored as context/dictionary, representing an underlying python class object, complete with method calls and variable getters/setters. 

### Public Client
Essentially the Market Data API, the public client is an unauthenticated set of endpoints for retrieving market data. These endpoints provide snapshots of market data. The public endpoints can be reached using `.cbpro.PublicClient`.
```q
q)pc:.cbpro.PublicClient[]
q)pc
                          | ::
get_currencies            | code.[code[foreign]]`.p.q2pargsenlist
get_product_24hr_stats    | code.[code[foreign]]`.p.q2pargsenlist
get_product_historic_rates| code.[code[foreign]]`.p.q2pargsenlist
get_product_order_book    | code.[code[foreign]]`.p.q2pargsenlist
get_product_ticker        | code.[code[foreign]]`.p.q2pargsenlist
get_product_trades        | code.[code[foreign]]`.p.q2pargsenlist
get_products              | code.[code[foreign]]`.p.q2pargsenlist
get_time                  | code.[code[foreign]]`.p.q2pargsenlist
url                       | {[qco; arg]
  acc: $[arg~(::); [arg:`; `get]; `set];..
auth                      | {[qco; arg]
  acc: $[arg~(::); [arg:`; `get]; `set];..
session                   | {[qco; arg]
  acc: $[arg~(::); [arg:`; `get]; `set];..
```
#### PublicClient Methods:
- get_products
```q
q)pc.get_products[]
id          base_currency quote_currency base_min_size base_max_size       quote_increment base_increment display_name min_market_funds max_market_funds margin_enabled post_only limit_only cancel_only status   status_message
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
"ETC-GBP"   "ETC"         "GBP"          "0.10000000"  "20000.00000000"    "0.00100000"    "0.00000001"   "ETC/GBP"    "10"             "100000"         0              0         0          0           "online" ""            
"XTZ-BTC"   "XTZ"         "BTC"          "1.00000000"  "100000.00000000"   "0.00000001"    "0.01000000"   "XTZ/BTC"    "0.001"          "10"             0              0         0          0           "online" ""            
"BAT-ETH"   "BAT"         "ETH"          "1.00000000"  "300000.00000000"   "0.00000001"    "1.00000000"   "BAT/ETH"    "0.01"           "500"            0              0         1          0           "online" ""            
"ETH-GBP"   "ETH"         "GBP"          "0.01000000"  "1400.00000000"     "0.01000000"    "0.00000001"   "ETH/GBP"    "10"             "1000000"        0              0         0          0           "online" ""            
"ETC-EUR"   "ETC"         "EUR"          "0.10000000"  "20000.00000000"    "0.00100000"    "0.00000001"   "ETC/EUR"    "10"             "100000"         0              0         0          0           "online" ""            
"ETH-EUR"   "ETH"         "EUR"          "0.01000000"  "1600.00000000"     "0.01000000"    "0.00000001"   "ETH/EUR"    "10"             "400000"         0              0         0          0           "online" ""      
...      
```

- get_product_ticker
```q
q) pc.get_product_ticker["ETH-USD"]
trade_id| 51157205
price   | "178.53000000"
size    | "0.11374059"
time    | "2019-09-02T23:30:22.842Z"
bid     | "178.5"
ask     | "178.53"
volume  | "60708.76736194"
```

- get_product_historic_rates
```q
q) pc.get_product_historic_rates["ETH-USD"; `granularity pykw 300]
1567467000 178.46 178.53 178.46 178.53 0.2821948
1567466700 177.83 178.43 178.21 178.4  629.3944 
1567466400 178.21 178.52 178.52 178.35 470.6056 
1567466100 178.37 178.77 178.75 178.37 420.9691 
1567465800 178.46 178.83 178.58 178.76 309.353  
1567465500 178.57 178.66 178.66 178.57 95.33785
```
### Authenticated Client
Authenticated endpoints available for order and account management. API access must be setup within your [account](https://www.pro.coinbase.com/profile/api) or [sandbox](https://public.sandbox.pro.coinbase.com/profile/api) environment. The `AuthenticatedClient` inherits all methods from the `PublicClient` class, so you will only need to initialize one if you are planning to integrate both into your script. The private endpoints can be reached using `.cbpro.AuthenticatedClient`.
```q
q)ac:.cbpro.AuthenticatedClient[("key";"secret";"passphrase";"https://api-public.sandbox.pro.coinbase.com")]
ac
                          | ::
cancel_all                | code.[code[foreign]]`.p.q2pargsenlist
cancel_order              | code.[code[foreign]]`.p.q2pargsenlist
close_position            | code.[code[foreign]]`.p.q2pargsenlist
coinbase_deposit          | code.[code[foreign]]`.p.q2pargsenlist
coinbase_withdraw         | code.[code[foreign]]`.p.q2pargsenlist
create_report             | code.[code[foreign]]`.p.q2pargsenlist
crypto_withdraw           | code.[code[foreign]]`.p.q2pargsenlist
deposit                   | code.[code[foreign]]`.p.q2pargsenlist
get_account               | code.[code[foreign]]`.p.q2pargsenlist
get_account_history       | code.[code[foreign]]`.p.q2pargsenlist
get_account_holds         | code.[code[foreign]]`.p.q2pargsenlist
get_accounts              | code.[code[foreign]]`.p.q2pargsenlist
get_coinbase_accounts     | code.[code[foreign]]`.p.q2pargsenlist
get_currencies            | code.[code[foreign]]`.p.q2pargsenlist
get_fills                 | code.[code[foreign]]`.p.q2pargsenlist
get_fundings              | code.[code[foreign]]`.p.q2pargsenlist
get_order                 | code.[code[foreign]]`.p.q2pargsenlist
get_orders                | code.[code[foreign]]`.p.q2pargsenlist
get_payment_methods       | code.[code[foreign]]`.p.q2pargsenlist
get_position              | code.[code[foreign]]`.p.q2pargsenlist
get_product_24hr_stats    | code.[code[foreign]]`.p.q2pargsenlist
get_product_historic_rates| code.[code[foreign]]`.p.q2pargsenlist
get_product_order_book    | code.[code[foreign]]`.p.q2pargsenlist
get_product_ticker        | code.[code[foreign]]`.p.q2pargsenlist
get_product_trades        | code.[code[foreign]]`.p.q2pargsenlist
get_products              | code.[code[foreign]]`.p.q2pargsenlist
get_report                | code.[code[foreign]]`.p.q2pargsenlist
get_time                  | code.[code[foreign]]`.p.q2pargsenlist
get_trailing_volume       | code.[code[foreign]]`.p.q2pargsenlist
margin_transfer           | code.[code[foreign]]`.p.q2pargsenlist
place_limit_order         | code.[code[foreign]]`.p.q2pargsenlist
place_market_order        | code.[code[foreign]]`.p.q2pargsenlist
place_order               | code.[code[foreign]]`.p.q2pargsenlist
place_stop_entry          | code.[code[foreign]]`.p.q2pargsenlist
place_stop_loss           | code.[code[foreign]]`.p.q2pargsenlist
repay_funding             | code.[code[foreign]]`.p.q2pargsenlist
withdraw                  | code.[code[foreign]]`.p.q2pargsenlist
url                       | {[qco; arg]
  acc: $[arg~(::); [arg:`; `get]; `set];..
auth                      | {[qco; arg]
  acc: $[arg~(::); [arg:`; `get]; `set];..
session                   | {[qco; arg]
  acc: $[arg~(::); [arg:`; `get]; `set];..
```
#### Getter/setter
We can access and manipulate the underlying object's attributes.
```q
// To 'get' the attribute value, call it as an empty function
q)ac.url[]
"https://api.pro.coinbase.com"
// To 'set' the attribute value, pass a value to the function
q)ac.url["https://api-public.sandbox.pro.coinbase.com"]
q)ac.url[]
"https://api-public.sandbox.pro.coinbase.com"
```

#### Pagination
Some calls are [paginated](https://docs.pro.coinbase.com/#pagination), meaning multiple calls must be made to receive the full set of data. The underlying library abstracts the HTTP requests in the form of generators - there is no direct method in q to handle generators, so a helper function must be called on the result.
```q
q)r:ac.get_fills[]
// Get all fills (will possibly make multiple HTTP requests)
q).py.list r
created_at                 trade_id product_id order_id                               user_id                    profile_id                             liquidity price           size         fee                   side  settled usd_volume             
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
"2019-09-03T01:11:03.75Z"  4885154  "BTC-USD"  "b831fcd4-1873-4bd6-d53c-35f468eb8082" "568c0b35a9f71500d5000102" "7426243a-1hd8-43fa-af97-47925a0f3586" ,"T"      "1010.16000000" "1.80561502" "5.4718802058096000"  "buy" 1       "1823.9600686032000000"
"2019-09-03T01:11:03.75Z"  4885153  "BTC-USD"  "b831fcd4-1873-4bd6-d53c-35f468eb8082" "568c0b35a9f71500d5000102" "7426243a-1hd8-43fa-af97-47925a0f3586" ,"T"      "1010.16000000" "8.19438498" "24.8329197941904000" "buy" 1       "8277.6399313968000000"
"2019-09-03T00:42:53.845Z" 4885152  "BTC-USD"  "f257f5e9-e823-4c4c-8766-9e14b0968822" "568c0b35a9f71500d5000102" "7426243a-1hd8-43fa-af97-47925a0f3586" ,"T"      "1010.16000000" "0.00986981" "0.0299102618088000"  "buy" 1       "9.9700872696000000"   
"2019-09-03T00:42:50.848Z" 4885151  "BTC-USD"  "0b89390e-93bf-499c-ddd3-1d8c003c76f3" "568c0b35a9f71500d5000102" "7426243a-1hd8-43fa-af97-47925a0f3586" ,"T"      "1010.16000000" "0.00986981" "0.0299102618088000"  "buy" 1       "9.9700872696000000"   
"2019-09-03T00:42:47.663Z" 4885150  "BTC-USD"  "0508e2d8-ec2b-4550-b492-d58204dfd78d" "568c0b35a9f71500d5000102" "7426243a-1hd8-43fa-af97-47925a0f3586" ,"T"      "1010.16000000" "0.00986981" "0.0299102618088000"  "buy" 1       "9.9700872696000000"   
"2019-09-03T00:42:38.705Z" 4885149  "BTC-USD"  "0f3d60ec-17ed-476b-db6b-2151edbde31f" "568c0b35a9f71500d5000102" "7426243a-1hd8-43fa-af97-47925a0f3586" ,"T"      "1010.16000000" "0.00986981" "0.0299102618088000"  "buy" 1       "9.9700872696000000"   
"2019-09-02T23:50:33.609Z" 4885147  "BTC-USD"  "bbdb8d8d-55e7-4b10-b59c-605102522fe0" "568c0b35a9f71500d5000102" "7426243a-1hd8-43fa-af97-47925a0f3586" ,"T"      "1010.16000000" "0.01168585" "0.0354137347080000"  "buy" 1       "11.8045782360000000"  
```

#### AuthenticatedClient Methods:
- get_accounts
```q
q)ac.get_accounts[]
id                                     currency oalance                     availaole              hold                   profile_id                            
----------------------------------------------------------------------------------------------------------------------------------------------------------------
"9eoo6d8e-o366-43ae-86f3-eoa356ocd9oe" "USD"    "24488488.0998830648200000" "24480986.59988306482" "508.5000000000000000" "7426243a-1hd8-43fa-af97-47925a0f3586"
"8883f043-d036-4496-8e98-a98d8594e5f6" "ETH"    "999999.4000000000000000"   "999999.4"             "0.0000000000000000"   "7426243a-1hd8-43fa-af97-47925a0f3586"
"o005a88d-6506-4d04-9e90-588224494860" "BTC"    "8006044.2298482480000000"  "8006044.229848248"    "0.0000000000000000"   "7426243a-1hd8-43fa-af97-47925a0f3586"
"dff58c84-o463-4ff8-90ae-40c8d4a038aa" "USDC"   "8000000.0000000000000000"  "8000000"              "0.0000000000000000"   "7426243a-1hd8-43fa-af97-47925a0f3586"
"2f044862-4059-464a-o9fd-4ec090e32cc0" "GBP"    "8000000.0000000000000000"  "8000000"              "0.0000000000000000"   "7426243a-1hd8-43fa-af97-47925a0f3586"
"o69825c4-dad8-4e08-oo3a-f8888a28f6oa" "EUR"    "8000000.0000000000000000"  "8000000"              "0.0000000000000000"   "7426243a-1hd8-43fa-af97-47925a0f3586"
"8e846c98-e2d9-4df9-o5e6-o28088344aed" "BAT"    "8000000.0000000000000000"  "8000000"              "0.0000000000000000"   "7426243a-1hd8-43fa-af97-47925a0f3586"
```
- place_market_order
```q
q)ac.place_market_order[pykwargs `product_id`side`funds!("BTC-USD";"sell";100.00)]
id             | "2a7ffad0-115a-48e7-a9af-f76501e89fc0"
product_id     | "BTC-USD"
side           | "sell"
stp            | "dc"
funds          | "100"
specified_funds| "100"
type           | "market"
post_only      | 0b
created_at     | "2019-09-03T01:46:29.797993Z"
fill_fees      | ,"0"
filled_size    | ,"0"
executed_value | ,"0"
status         | "pending"
settled        | 0b
```


    
	



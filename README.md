# Q Client  - Coinbase Pro
The recent boom in cryptocurrency has ushered in a wave of technological innovation - and propelled algo-trading to the top of the trend charts. As an industry leader in this domain, Kx continues to push the boundaries of its high-performance database platform. In this paper, we'll explore the versatility of q - by leveraging kdb+ fusion technology (embedPy), we've created an interactive trading and market data client for the [Coinbase Pro API](https://docs.pro.coinbase.com/). Simple to use, and easy to install, the client provides seamless integration between trade execution, order management, and the real-time, in-memory computational power of kdb.

#### Benefits
- Intuitive q/kdb wrapper for both public and  authenticated endpoints.
- No handling of nuanced API calls or working with cumbersome libraries, the client provides full abstraction for every API endpoint.
	- Easy to use functions, conventional q execution and access.
	- Auto pagination of API results, converts and casts into native q datatypes.
    - Extension methods for more complex order types (stop loss, stop entry).

This API attempts to highlight real world application of q/kdb technology through an operating interface to Coinbase Pro, in order to use it to its full potential, you must familiarize yourself with the official documentation. **PLEASE BE AWARE, LIVE TRADE EXECUTION ENABLED**

-   [https://docs.pro.coinbase.com/](https://docs.pro.coinbase.com/)

## Requirements
- Linux
- Anaconda Python >= 3.5

## Getting Started
##### Install the client
```bash
❯ git clone https://github.com/michaelsimonelli/qoinbase-q.git
```
##### Create and activate the conda environment
```bash
❯ cd qoinbase-q
❯ conda env create -f environment.yml
❯ conda activate cbpro
```
##### Start the qoinbase-q session
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
And we are good to go, the client can be used out of the box with little to no configuration!

## The Basics
Our library is stored in the **.cbpro** namespace. At a quick glimpse, this library contains:
```q
q)key `.cbpro
`AuthenticatedClient`CBProAuth`OrderBook`PublicClient`WebsocketClient
``` 
The 'clients' are projected functions that instantiate an underlying python class.
When a function is called, it returns a function library of the underlying class' methods and properties (stored as a dictionary) - giving q a pseudo object oriented implementation.
##### Instantiating a class
```q
q)pc:.cbpro.PublicClient[]
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
  acc: $[arg~(::); [arg:`; `get]; `set];
..
```
##### Calling a function
Standard embedPy convention applies when calling auto-mapped functions
```q
q)pc.get_product_historic_rates["BTC-USD"; `granularity pykw 300]
1581166800 9807.76 9817.27 9814.68 9816.94 30.99798 
1581166500 9814.67 9817.27 9817.26 9814.68 8.381697 
1581166200 9805.6  9817.27 9805.62 9817.27 19.71972 
1581165900 9805.61 9824.9  9824.89 9805.61 12.40951 
1581165600 9824.88 9827.78 9826.79 9824.89 8.307047 
1581165300 9808.53 9831.87 9817.91 9828.18 34.51228 
1581165000 9803.68 9840.01 9840    9814.1  86.51028 
```
##### Accessing properties
To *get* a property, call as a *nullary* function
```q
q)pc.url[]
"https://api.pro.coinbase.com"
```
To *set* the property, call with a value
```q
q)pc.url["newUrl"]
q)pc.url[]
"newUrl"
```
>For an extensive view of the extendPy implementation, see the appendix 

### The Coinbase Pro API
The Coinbase Pro API is separated into two categories: **trading** and **feed**. Trading APIs require authentication and provide access to placing orders and other account information. Feed APIs provide market data and are public. 

Coinbase also offers two API environments: **production** and **sandbox**. 
Sandbox is available for testing API connectivity and web trading. While the sandbox only hosts a subset of the production order books, all of the exchange functionality is available. Login sessions and API keys are separate from production. Use the sandbox web interface to create keys in the sandbox environment.
[Sandbox Website](https://public.sandbox.pro.coinbase.com/)

## The Q Client
The Q client can interact with the Coinbase Pro API

**PublicClient**
Essentially a market data API, the public client is an unauthenticated set of endpoints for retrieving market data. 
```q
// production
q) pc:.cbpro.PublicClient[]
// sandbox
q) pc:.cbpro.PublicClient["https://api-public.sandbox.pro.coinbase.com"]
```

**AuthenticatedClient**
Authenticated endpoints for placing order and account management. API access must be setup within your [account](https://www.pro.coinbase.com/profile/api) or [sandbox](https://public.sandbox.pro.coinbase.com/profile/api) environment. 

```q
// production
q)ac:.cbpro.AuthenticatedClient["key"; "secret"; "passphrase"]
// sandbox
q)ac:.cbpro.AuthenticatedClient["key"; "secret"; "passphrase"; "https://api-public.sandbox.pro.coinbase.com"]
```
The `AuthenticatedClient` inherits all methods from the `PublicClient` class, so you will only need to initialize one if you are planning to integrate both into your script. 

### The API Interface
A wrapper interface is provided for the Public and Authenticated clients, it provides:
- conventional q execution
- seamless datatype conversion
- auto-pagination of iterators
- advanced trade execution

**Initialize the API**
```.api.init[client;env]```

**Parameters**
- client
	- `public - unauthenticated client (market data API)
	- `auth - authenticated client (trade and order management)
- env
	-	`live - production
	-	`test - sandbox


```q
// Public client, no auth
q).api.init[`public;`test]
2020.02.08T12:39:04.353 [CLI] Loading mkt api library
2020.02.08T12:39:04.358 [CLI] Loading ord api library
```

If initializing an authenticated client, the API key/secret/pass must be supplied directly in the function
```q
// Auth client, with key
q).api.init[`auth;`test;"key";"secret";"pass"];
2020.02.08T12:39:04.353 [CLI] Loading mkt api library
2020.02.08T12:39:04.358 [CLI] Loading ord api library
```
**OR**
Supplied via config, and called with just *client* and *env* params
```bash
# start script
 export CBPRO_API_KEY=""
 export CBPRO_API_SECRET=""
 export CBPRO_API_PASSPHRASE=""
```
```q
// Auth client, via config
q).api.init[`auth;`test]
2020.02.08T12:39:04.353 [CLI] Loading mkt api library
2020.02.08T12:39:04.358 [CLI] Loading ord api library
```
#### Standard VS Wrapper
```q
// standard
pc.get_products[]
id          base_currency quote_currency base_min_size base_max_size      quote_increment base_increment display_name min_market_funds max_market_funds margin_enabled post_only limit_only cancel_only status   status_message
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
"ETH-BTC"   "ETH"         "BTC"          "0.01000000"  "1000000.00000000" "0.00001000"    "0.00000001"   "ETH/BTC"    "0.001"          "80"             0              0         0          0           "online" ""            
"BAT-USDC"  "BAT"         "USDC"         "1.00000000"  "300000.00000000"  "0.00000100"    "1.00000000"   "BAT/USDC"   ,"1"             "100000"         0              0         0          0           "online" ""            
"BTC-USD"   "BTC"         "USD"          "0.00100000"  "10000.00000000"   "0.01000000"    "0.00000001"   "BTC/USD"    "10"             "1000000"        1              0         0          0           "online" ""            
"BTC-EUR"   "BTC"         "EUR"          "0.00100000"  "10000.00000000"   "0.01000000"    "0.00000001"   "BTC/EUR"    "10"             "600000"         0              0         0          0           "online" ""            
"BTC-GBP"   "BTC"         "GBP"          "0.00100000"  "10000.00000000"   "0.01000000"    "0.00000001"   "BTC/GBP"    "10"             "200000"         0              0         0          0           "online" ""            
"LINK-USDC" "LINK"        "USDC"         "1.00000000"  "800000.00000000"  "0.00000100"    "1.00000000"   "LINK/USDC"  "10"             "100000"         0              0         0          0           "online" ""            


// wrapper
.mkt.getProducts[]
sym     | id        base_currency quote_currency base_min_size base_max_size quote_increment base_increment display_name min_market_funds max_market_funds margin_enabled post_only limit_only cancel_only status status_message
--------| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
BTCEUR  | BTC-EUR   BTC           EUR            0.001         10000         0.01            1e-08          BTC/EUR      10               600000           0              0         0          0           online ""            
BTCGBP  | BTC-GBP   BTC           GBP            0.001         10000         0.01            1e-08          BTC/GBP      10               200000           0              0         0          0           online ""            
BTCUSD  | BTC-USD   BTC           USD            0.001         10000         0.01            1e-08          BTC/USD      10               1000000          1              0         0          0           online ""            
BATUSDC | BAT-USDC  BAT           USDC           1             300000        1e-06           1              BAT/USDC     1                100000           0              0         0          0           online ""            
ETHBTC  | ETH-BTC   ETH           BTC            0.01          1000000       1e-05           1e-08          ETH/BTC      0.001            80               0              0         0          0           online ""            
LINKUSDC| LINK-USDC LINK          USDC           1             800000        1e-06           1              LINK/USDC    10               100000           0              0         0          0           online ""            
       
// Notice the wrapped function outputs everything in intuitive kdb types
```
#### Auto Pagination
```q
q)r:ac.get_fills["BTC-USD"]
foreign
// returns an iterator that needs to be generated
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

// returns casted table with out generator
q).ord.getFills[`BTCUSD]
created_at              trade_id product_id order_id                             user_id                  profile_id                           liquidity price   size       fee        side settled usd_volume
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
2020.02.08T20:39:14.141 9183355  BTC-USD    efed7522-35cd-436d-8fbf-44e64c2fe821 568c0b35a9f71500d5000102 7645849f-1de8-46df-af97-38865f0e3876 M         9860    0.01       0.493      sell 1       98.6      
2020.02.08T20:24:12.964 9183188  BTC-USD    799591f3-b319-448d-958a-2bd2fcc57bb7 568c0b35a9f71500d5000102 7645849f-1de8-46df-af97-38865f0e3876 T         9860.48 0.01       0.493024   sell 1       98.6048   
2020.01.04T17:21:13.726 8146290  BTC-USD    21eefa9d-247e-4d50-8c3b-cee709f72fe0 568c0b35a9f71500d5000102 7645849f-1de8-46df-af97-38865f0e3876 M         20100   5.424e-05  0.00545112 sell 1       1.090224  
2020.01.04T17:20:13.924 8146256  BTC-USD    21eefa9d-247e-4d50-8c3b-cee709f72fe0 568c0b35a9f71500d5000102 7645849f-1de8-46df-af97-38865f0e3876 M         20100   0.00049661 0.04990931 sell 1       9.981861  
2020.01.04T17:13:14.127 8145987  BTC-USD    21eefa9d-247e-4d50-8c3b-cee709f72fe0 568c0b35a9f71500d5000102 7645849f-1de8-46df-af97-38865f0e3876 M         20100   0.00049661 0.04990931 sell 1       9.981861 
```

### Execute Trades
**Market Order**
```q
q)r:.ord.placeMarketOrder[`BTCUSD;`buy;00.1]
id            | 8d87bb96-beee-4550-9208-bbd49d05ee3d
size          | 0.1
product_id    | `BTC-USD
side          | `buy
stp           | `dc
funds         | 2.63393e+07
type          | `market
post_only     | ,"0"
created_at    | 2020.02.08T21:08:13.494
fill_fees     | 0f
filled_size   | 0f
executed_value| 0f
status        | `pending
settled       | ,"0"

q).ord.getOrder[r`id]
id            | 8d87bb96-beee-4550-9208-bbd49d05ee3d
size          | 0.1
product_id    | `BTC-USD
profile_id    | 7645849f-1de8-46df-af97-38865f0e3876
side          | `buy
funds         | 2.63393e+07
type          | `market
post_only     | ,"0"
created_at    | 2020.02.08T21:08:13.494
done_at       | 2020.02.08T21:08:13.499
done_reason   | `filled
fill_fees     | 4.93237
filled_size   | 0.1
executed_value| 986.474
status        | `done
settled       | ,"1"
```

**Limit Order**
```q
q)r:.ord.placeLimitOrder[`BTCUSD;`buy;9885;0.1]
id            | 137a3307-e08d-4fde-a5ae-66091d162986
price         | 9885f
size          | 0.1
product_id    | `BTC-USD
side          | `buy
type          | `limit
time_in_force | `GTC
post_only     | ,"0"
created_at    | 2020.02.08T21:29:37.974
fill_fees     | 0f
filled_size   | 0f
executed_value| 0f
status        | `open
settled       | ,"0"

q).ord.getOrder[r`id]
id            | 137a3307-e08d-4fde-a5ae-66091d162986
price         | 9885f
size          | 0.1
product_id    | `BTC-USD
profile_id    | 7645849f-1de8-46df-af97-38865f0e3876
side          | `buy
type          | `limit
time_in_force | `GTC
post_only     | ,"0"
created_at    | 2020.02.08T21:29:37.974
done_at       | 2020.02.08T21:33:53.966
done_reason   | `filled
fill_fees     | 4.9425
filled_size   | 0.1
executed_value| 988.5
status        | `done
settled       | ,"1"
```

**Stop Loss**
```q
q)r:.ord.placeStopLoss[`BTCUSD;9881.00;9880.00;0.01]
id            | fbd4ec20-afc4-4524-b469-0ee55adb12cc
price         | 9880f
size          | 0.01
product_id    | `BTC-USD
profile_id    | 7645849f-1de8-46df-af97-38865f0e3876
side          | `sell
type          | `limit
time_in_force | `GTC
post_only     | ,"0"
created_at    | 2020.02.08T21:19:50.592
fill_fees     | 0f
filled_size   | 0f
executed_value| 0f
status        | `active
settled       | ,"0"
stop          | `loss
stop_price    | 9881f
id                                   price size product_id profile_id                           side type  time_in_force post_only created_at              fill_fees filled_size executed_value status settled stop stop_price
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
fbd4ec20-afc4-4524-b469-0ee55adb12cc 9880  0.01 BTC-USD    7645849f-1de8-46df-af97-38865f0e3876 sell limit GTC           ,"0"      2020.02.08T21:19:50.592 0         0           0              active ,"0"    loss 9881      


q).ord.getOrder[r`id]
id            | fbd4ec20-afc4-4524-b469-0ee55adb12cc
price         | 9880f
size          | 0.01
product_id    | `BTC-USD
profile_id    | 7645849f-1de8-46df-af97-38865f0e3876
side          | `sell
type          | `limit
time_in_force | `GTC
post_only     | ,"0"
created_at    | 2020.02.08T21:19:50.592
fill_fees     | 0f
filled_size   | 0f
executed_value| 0f
status        | `active
settled       | ,"0"
stop          | `loss
stop_price    | 9881f
```

**Stop Entry**
```q
q)id            | becf4781-9b97-43ef-bbdd-149db604a475
price         | 9885f
size          | 0.01
product_id    | `BTC-USD
side          | `buy
stp           | `dc
type          | `limit
time_in_force | `GTC
post_only     | ,"0"
created_at    | 2020.02.08T21:21:19.976
stop          | `entry
stop_price    | 9881f
fill_fees     | 0f
filled_size   | 0f
executed_value| 0f
status        | `pending
settled       | ,"0"

q).ord.getOrder[r`id]
id            | becf4781-9b97-43ef-bbdd-149db604a475
price         | 9885f
size          | 0.01
product_id    | `BTC-USD
profile_id    | 7645849f-1de8-46df-af97-38865f0e3876
side          | `buy
type          | `limit
time_in_force | `GTC
post_only     | ,"0"
created_at    | 2020.02.08T21:21:19.976
done_at       | 2020.02.08T21:21:19.981
done_reason   | `filled
fill_fees     | 0.4941205
filled_size   | 0.01
executed_value| 98.8241
status        | `done
settled       | ,"1"
stop          | `entry
stop_price    | 9881f
```
> For in-depth docs on every API function, see [qoinbase-q](https://github.com/michaelsimonelli/qoinbase-q)

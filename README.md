# Q Client  - Coinbase Pro
The recent boom in cryptocurrency has ushered in a wave of technological innovation - and propelled algo-trading to the top of the trend charts. As an industry leader in this domain, Kx continues to push the boundaries of its high-performance database platform. In this paper, we'll explore the versatility of q - by leveraging kdb+ fusion technology (embedPy), we've created an interactive trading and market data client for the [Coinbase Pro API](https://docs.pro.coinbase.com/). Simple to use, and easy to install, the client provides seamless integration between trade execution, order management, and the real-time, in-memory computational power of kdb.

#### Benefits
- Intuitive q/kdb wrapper for both public and  authenticated endpoints.
- Abstraction of API calls/HTTP requests
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

## Introduction
Our library is stored in the **.cbpro** namespace. At a quick glimpse, this library contains:
```q
q)key `.cbpro
`AuthenticatedClient`CBProAuth`OrderBook`PublicClient`WebsocketClient
``` 
The 'clients' are projected functions that instantiate an underlying python class.
When a function is called, it returns a function library of the underlying class' methods and properties (stored as a dictionary) - giving q a pseudo object oriented implementation.

#### Instantiating a Class
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
#### Calling a function
Standard embedPy convention applies when calling auto-mapped instance methods
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
#### Accessing properties
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
#### Pagination and Generators 
Some calls are [paginated](https://docs.pro.coinbase.com/#pagination), meaning multiple calls must be made to receive the full set of data. Python abstracts this away as a generator, but kdb has no means of accessing a python generator. 

With the standard mapped function, the result we be returned as foreign and an iterator will have to be called on the data to access it.
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
```
However, with the enhanced API wrapper, the data is auto-iterated and displayed in full
```q
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
>See appendix for more details on python reflection

## The API Client
The Coinbase Pro REST API is segregated into two endpoints: **trading** and **feed**. Trading APIs require authentication and provide access to placing orders and other account information. Feed APIs provide market data and are public. 

Coinbase also offers two environments: **production** and **sandbox**. 
Sandbox is available for testing API connectivity and web trading. While the sandbox only hosts a subset of the production order books, all of the exchange functionality is available. Login sessions and API keys are separate from production. Use the sandbox web interface to create keys in the sandbox environment.
[Sandbox Website](https://public.sandbox.pro.coinbase.com/)

Communication to the API is established via an embedded python module, which utilizes an HTTP request library to simplifying the handling of responses from the API. The module is abstracted and mapped directly into a callable kdb context - allowing for native API interaction.

**PublicClient**
Essentially a market data API, the public client is an unauthenticated set of endpoints for retrieving market data. 

Instantiate a public client
```q
// production
q) pc:.cbpro.PublicClient[]
// sandbox
q) pc:.cbpro.PublicClient["https://api-public.sandbox.pro.coinbase.com"]
```

**AuthenticatedClient**
Authenticated endpoints for placing order and account management. API access must be setup within your [account](https://www.pro.coinbase.com/profile/api) or [sandbox](https://public.sandbox.pro.coinbase.com/profile/api) environment. 

Instantiate an authenticated client
```q
// production
q)ac:.cbpro.AuthenticatedClient["key"; "secret"; "passphrase"]
// sandbox
q)ac:.cbpro.AuthenticatedClient["key"; "secret"; "passphrase"; "https://api-public.sandbox.pro.coinbase.com"]
```
The `AuthenticatedClient` inherits all methods from the `PublicClient` class, so you will only need to initialize one if you are planning to integrate both into your script. 

### The API Library
An enhanced library is provided for both the market and order API (feed and trade). This library wraps the standard auto-mapped functions to provide additionally functionality and benefits.
- conventional q execution
- seamless datatype conversion
- auto-pagination of iterators
- advanced trade execution

**Initialize the API**
```.api.init[client;env]```

**Parameters**
- client
	- `public - unauthenticated client (market data library **ONLY**)
	- `auth - authenticated client (trade and order management + market data)
- env
	-	`live - production
	-	`test - sandbox

```q
// Public client, no auth
q).api.init[`public;`test]
2020.02.08T12:39:04.353 [CLI] Loading mkt api library
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

Once initialized, the market and order libraries are accessed via the **.mkt** and **.ord** namespaces, respectively.

#### Market Data Library
Useful functions to query and interact with public market data

**getCurrencies**
```q
q).mkt.getCurrencies[]
id  | name                  min_size status message max_precision convertible_to
----| --------------------------------------------------------------------------
BAT | Basic Attention Token 1        online ""      1             `             
LINK| Chainlink             1        online ""      1e-08         `             
USD | United States Dollar  0.01     online ""      0.01          ,`USDC        
BTC | Bitcoin               1e-08    online ""      1e-08         `             
GBP | British Pound         0.01     online ""      0.01          `             
EUR | Euro                  0.01     online ""      0.01          `             
ETH | Ether                 1e-08    online ""      1e-08         `             
USDC| USD Coin              1e-06    online ""      1e-06         ,`USD         
```
**getProducts**
```q
q).mkt.getProducts[]
sym     | id        base_currency quote_currency base_min_size base_max_size quote_increment base_increment display_name min_market_funds max_market_funds margin_enabled post_only limit_only cancel_only status status_message
--------| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
BTCUSD  | BTC-USD   BTC           USD            0.001         10000         0.01            1e-08          BTC/USD      10               1000000          1              0         0          0           online ""            
BTCGBP  | BTC-GBP   BTC           GBP            0.001         10000         0.01            1e-08          BTC/GBP      10               200000           0              0         0          0           online ""            
LINKUSDC| LINK-USDC LINK          USDC           1             800000        1e-06           1              LINK/USDC    10               100000           0              0         0          0           online ""            
BTCEUR  | BTC-EUR   BTC           EUR            0.001         10000         0.01            1e-08          BTC/EUR      10               600000           0              0         0          0           online ""            
BATUSDC | BAT-USDC  BAT           USDC           1             300000        1e-06           1              BAT/USDC     1                100000           0              0         0          0           online ""            
ETHBTC  | ETH-BTC   ETH           BTC            0.01          1000000       1e-05           1e-08          ETH/BTC      0.001            80               0              0         0          0           online ""            
  
```
**getProduct24hrStats**
```q
q).mkt.getProduct24hrStats[`BTCUSD]
open        | 9779.96
high        | 9930.03
low         | 9676.75
volume      | 39741.31
last        | 9897.87
volume_30day| 6333819
```
**getProductHistoricRates**
```q
q).mkt.getProductHistoricRates[`BTCUSD; 900; 2020.02.07T08:00:00.000; 2020.02.07T09:00:00.000]
time                    low     high    open    close   volume  
----------------------------------------------------------------
2020.02.07T09:00:00.000 9754.65 9763.54 9754.65 9763.52 211.8582
2020.02.07T08:45:00.000 9754.65 9756.4  9756.38 9754.65 191.5283
2020.02.07T08:30:00.000 9756.38 9775.68 9775.66 9756.4  432.2584
2020.02.07T08:15:00.000 9775.66 9775.93 9775.91 9775.66 517.2051
2020.02.07T08:00:00.000 9775.91 9779.41 9779.39 9775.91 523.4472
```
**getProductTrades**
```q
q).mkt.getProductTrades[`BTCUSD;9185670;9185690;10]
time                       trade_id price   size   side
-------------------------------------------------------
"2020-02-08T22:55:43.654Z" 9185689  9922.56 0.001  sell
"2020-02-08T22:55:42.229Z" 9185688  9922.55 9.2903 buy 
"2020-02-08T22:55:34.6Z"   9185687  9922.55 0.488  buy 
"2020-02-08T22:55:18.966Z" 9185686  9922.55 0.488  buy 
"2020-02-08T22:55:13.65Z"  9185685  9922.55 0.001  buy 
"2020-02-08T22:55:13.401Z" 9185684  9922.55 0.496  buy 
"2020-02-08T22:55:03.772Z" 9185683  9922.55 0.488  buy 
"2020-02-08T22:54:57.597Z" 9185682  9922.55 0.496  buy 
"2020-02-08T22:54:48.302Z" 9185681  9922.55 0.488  buy 
"2020-02-08T22:54:44.336Z" 9185680  9922.56 0.001  sell
```
**getProductTicker**
```q
q).mkt.getProductTicker[`BTCUSD]
trade_id| "9185706"
price   | 9922.55
size    | 0.942
time    | "2020-02-08T22:57:38.089844Z"
bid     | 9922.55
ask     | 9922.57
volume  | 39693.91
```
**getProductOrderBook**
```q
q).mkt.getProductOrderBook[`BTCUSD;2]
sequence| 113917597
bids    | +`price`size`num!(9922.55 9922.54 9922.53 9922.52 9922.51 9922.5 9922.49 9922.48 9917.64 9917.61 9914.33
asks    | +`price`size`num!(9922.57 9922.58 9922.59 9922.6 9922.61 9922.62 9922.63 9922.64 9925.46 9927.12 9946.4
```
#### Order Management Library
Helper functions for viewing and analyzing account info as well as enhanced order execution functionality.

**getAccounts**
```q
q).ord.getAccounts[]
id                                   currency balance      available    hold    profile_id                           trading_enabled
------------------------------------------------------------------------------------------------------------------------------------
00000000-0000-0000-0000-000000000000 BTC      1006423      1006423      0       00000000-0000-0000-0000-000000000000 1              
00000000-0000-0000-0000-000000000000 USDC     0            0            0       00000000-0000-0000-0000-000000000000 1              
00000000-0000-0000-0000-000000000000 USD      2.646911e+07 2.646901e+07 98.9925 00000000-0000-0000-0000-000000000000 1              
00000000-0000-0000-0000-000000000000 LINK     0            0            0       00000000-0000-0000-0000-000000000000 1              
00000000-0000-0000-0000-000000000000 GBP      2.2048e+07   2.2048e+07   0       00000000-0000-0000-0000-000000000000 1              
00000000-0000-0000-0000-000000000000 EUR      2.2048e+07   2.2048e+07   0       00000000-0000-0000-0000-000000000000 1              
00000000-0000-0000-0000-000000000000 ETH      1102000      1102000      0       00000000-0000-0000-0000-000000000000 1              
00000000-0000-0000-0000-000000000000 BAT      1000000      1000000      0       00000000-0000-0000-0000-000000000000 1                      
```
**getAccountHistory**
```q
q).ord.getAccountHistory[`USD;`fee;`]
created_at              id        amount        balance      type
-----------------------------------------------------------------
2020.02.08T21:54:14.330 102547930 -0.494        2.646911e+07 fee 
2020.02.08T21:54:14.326 102547925 -0.494        2.646901e+07 fee 
2020.02.08T21:33:53.980 102544744 -4.9425       2.646891e+07 fee 
2020.02.08T21:21:19.992 102543592 -0.4941205    2.64699e+07  fee 
2020.02.08T21:08:13.508 102542316 -4.93237      2.647e+07    fee 
2020.02.08T21:07:30.602 102542245 -4.93237      2.647099e+07 fee 
2020.02.08T20:39:14.151 102541071 -0.493        2.647199e+07 fee 
2020.02.08T20:24:12.977 102539876 -0.493024     2.647189e+07 fee 
2020.01.04T17:21:13.736 94139789  -0.00545112   2.647179e+07 fee 
```
**getFills**
```q
q).ord.getFills[`BTCUSD]
reated_at              trade_id product_id order_id                             user_id                  profile_id                           liquidity price   size       fee        side settled usd_volume
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
2020.02.08T21:54:14.314 9184343  BTC-USD    00000000-0000-0000-0000-000000000000 00000000000000000000000 00000000-0000-0000-0000-000000000000 M         9880    0.01       0.494      sell 1       98.8      
2020.02.08T21:54:14.314 9184342  BTC-USD    00000000-0000-0000-0000-000000000000 00000000000000000000000 00000000-0000-0000-0000-000000000000 M         9880    0.01       0.494      sell 1       98.8      
2020.02.08T21:33:53.966 9183850  BTC-USD    00000000-0000-0000-0000-000000000000 00000000000000000000000 00000000-0000-0000-0000-000000000000 M         9885    0.1        4.9425     buy  1       988.5     
2020.02.08T21:21:19.981 9183693  BTC-USD    00000000-0000-0000-0000-000000000000 00000000000000000000000 00000000-0000-0000-0000-000000000000 T         9882.41 0.01       0.4941205  buy  1       98.8241   
2020.02.08T21:08:13.499 9183506  BTC-USD    00000000-0000-0000-0000-000000000000 00000000000000000000000 00000000-0000-0000-0000-000000000000 T         9864.74 0.1        4.93237    buy  1       986.474   
2020.02.08T21:07:30.593 9183495  BTC-USD    00000000-0000-0000-0000-000000000000 00000000000000000000000 00000000-0000-0000-0000-000000000000 T         9864.74 0.1        4.93237    buy  1       986.474   
```
**getOrders**
```q
ord.getOrders[`done]
id                                   price   size               product_id profile_id                           side type   time_in_force post_only created_at              done_at                 done_reason fill_fees  filled_size executed_value status settled stop  stop_price funds        specified_funds
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
00000000-0000-0000-0000-000000000000 9885    "0.10000000"       BTC-USD    7645849f-1de8-46df-af97-38865f0e3876 buy  limit  GTC           0         2020.02.08T21:29:37.974 2020.02.08T21:33:53.966 filled      4.9425     0.1         988.5          done   1                                                    
00000000-0000-0000-0000-000000000000 9885    "0.01000000"       BTC-USD    7645849f-1de8-46df-af97-38865f0e3876 buy  limit  GTC           0         2020.02.08T21:21:19.976 2020.02.08T21:21:19.981 filled      0.4941205  0.01        98.8241        done   1       entry 9881                                   
00000000-0000-0000-0000-000000000000 9880    "0.01000000"       BTC-USD    7645849f-1de8-46df-af97-38865f0e3876 sell limit  GTC           0         2020.02.08T21:19:50.592 2020.02.08T21:54:14.314 filled      0.494      0.01        98.8           done   1       loss  9881                                   
00000000-0000-0000-0000-000000000000 9880    "0.01000000"       BTC-USD    7645849f-1de8-46df-af97-38865f0e3876 sell limit  GTC           0         2020.02.08T21:19:43.543 2020.02.08T21:54:14.314 filled      0.494      0.01        98.8           done   1       loss  9881                                   
00000000-0000-0000-0000-000000000000         "0.10000000"       BTC-USD    7645849f-1de8-46df-af97-38865f0e3876 buy  market               0         2020.02.08T21:08:13.494 2020.02.08T21:08:13.499 filled      4.93237    0.1         986.474        done   1                        2.63393e+07                 
00000000-0000-0000-0000-000000000000         "0.10000000"       BTC-USD    7645849f-1de8-46df-af97-38865f0e3876 buy  market               0         2020.02.08T21:07:30.588 2020.02.08T21:07:30.593 filled      4.93237    0.1         986.474        done   1                        2.634028e+07                
```

#### Trade Execution
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
r:.ord.placeStopEntry[`BTCUSD;9881.00;9885.00;0.01]
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

## extendPy
*BETA library to extend the functionality of embedPy.*
It's core functionality is to provide seamless reflection of a python module into callable q context. It achieves this through recursively inspecting the python module and its members, building a dictionary mapping of *member name* **->** *instance object*, and then importing that dictionary into kdb as a dictionary of projections. The source code is available here [extendPy](https://github.com/michaelsimonelli/extendPy)

### Reflection
Consider the class ```Bar``` in file ```foo.py``
```python
class Bar:
    def __init__(self, prop, multi, text='some basic text'):
        self.prop = prop
        self.multi = multi
        self.text = text

    def addFunc(self, x):
        print('adding %i with %i' % (self.prop, x))
        return self.prop + x

    def multiFunc(self, x):
        print('adding %i with %i times %i' % (self.prop, x, self.multi))
        return (self.prop + x) * self.multi

    def output(self, x):
        print('concat ' + x + ' with ' + self.text)
        return x + ' ' + self.text
```
The module would be imported as
```q
.py.import[`foo]
```
And then *reflected* with
```q
.py.reflection.emulate[`foo]
```
The class has been mapped to kdb, as a function library
```q
Bar| {[x;y] x[y]}[{[obj; atr; arg]
  init: atr[`functions][`$"__init__"];
  params: init[`parameters];
  required: params[::;`required];

  if[(arg~(::)) and (any required);
    '"Missing required parameters: ",", " sv string where required];

  blk: .ut.blankNS;
  arg: .py.reflection.priv.args[arg];
  ins: $[1<count arg;.;@][obj;arg];

  atr[`vars]: .py.vars[ins];
  atr: @[atr;`functions;{x _ `$"__init__"}];

  cxt: blk,(,/)value .ut.eachKV[`doc _ atr;{.py.reflection.priv[y;`cxt][x;z]}[ins]];

  cxt}[{[f;x]embedPy[f;x]}[foreign]enlist;...projection
```
We can now *instantiate* the class via
```q
q)bar:.foo.Bar[100;2]
```
- The function valence is flexible depending on the underlying class
- Both keyword and positional arguments are accepted
- Default values can be over loaded
- No embedPy pykw, pykwargs required
```q
q)boo:.foo.Bar[1000;2;" new default"]
..
q)goo:.foo.Bar[10;`multi`text!(5;"goo gravy")]
```

#### Accessing properties
To *get* a property, call as a *nullary* function
```q
q)bar.text[]
"some basic text"
```
To *set* the property, call with a value
```q
q)bar.url["some new text"]
q)bar.url[]
"some new text"
```

#### Examples
Quickly import entire modules, use helpful utility functions
```q
.py.import[`os]
.py.reflection.emulate[`os]
.py.import[`sys]
.py.reflection.emulate[`sys]

.os.name`
"posix"
.sys.path`
""
"/home/mike/anaconda3/envs/cbpro/q"
"/home/mike/anaconda3/envs/cbpro/lib/python37.zip"
"/home/mike/anaconda3/envs/cbpro/lib/python3.7"
"/home/mike/anaconda3/envs/cbpro/lib/python3.7/lib-dynload"
"/home/mike/anaconda3/envs/cbpro/lib/python3.7/site-packages"
```

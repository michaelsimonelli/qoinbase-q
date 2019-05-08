
//
// While the underlying library is fully callable in q, 
// it doesn't always return the most intuitive or useful data structures.
// Python generators can even be returned in some instances
// With this wrapper, all of the string casting, data transformation, and itera


///////////////////////////////////////
// MARKET DATA API                   //
///////////////////////////////////////
//
// Accessibility wrappers around the default API.
//
// The Market Data API is an unauthenticated set of endpoints for retrieving market data. 
// These endpoints provide snapshots of market data.
//
// * For documentation and full functionality of the underlying library
// see: https://github.com/michaelsimonelli/qoinbase-py
//
// * For the full coinbase pro API documentation
// see: https://docs.pro.coinbase.com/
// ____________________________________________________________________________

// Market Data Client
.mkt.CLI:();

///
// List known currencies
//
// example:
// q) .mkt.getCurrencies[]
// 
// note:
// The fields (message, details, and convertible_to) are stripped from api result.
// For more detailed information, call .mkt.CLI.get_currencies[].
//
// returns:
// ccy [ktable] - currency reference data
//  c             | t f a k e
//  --------------| ---------
//  id            | s     y USD
//  name          | s       United States Dollar
//  min_size      | f       0.01
//  status        | s       `online
//
// wraps: get_currencies
//  api - https://docs.pro.coinbase.com/#get-currencies
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/qoinbase/public_client.py#L236
.mkt.getCurrencies:{[]
  res: .mkt.CLI.get_currencies[];
  scm: `id`name`min_size`status!"SSFS";
  ccy: (key scm) #/: res;
  ccy: 1!scm[cols ccy] .ut.cast/: ccy;
  ccy};

///
// Get a list of available currency pairs for trading
//
// example:
// q) .mkt.getProducts[]
//
// returns:
// products [ktable] - product reference data, keyed on sym for accessibility
//  c             | t f a k e
//  --------------| ---------
//  sym             | s   y `BTCUSD
//  id              | s     `BTC-USD
//  base_currency   | s     `BTC
//  quote_currency  | s     `USD
//  base_min_size   | f     0.001
//  base_max_size   | f     70f
//  quote_increment | f     0.01
//  display_name    | s     `BTC/USD
//  status          | s     `online
//  margin_enabled  | b     0b
//  status_message  | c     ""
//  min_market_funds| f     10f
//  max_market_funds| f     1000000f
//  post_only       | b     0b
//  limit_only      | b     0b
//  cancel_only     | b     0b
//  accessible      | b     0b
//
// wraps: get_products
//  api - https://docs.pro.coinbase.com/#get-products
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/qoinbase/public_client.py#L33
.mkt.getProducts:{[]
  res: .mkt.CLI.get_products[];
  scm: `id`base_currency`quote_currency`base_min_size`base_max_size`base_increment`quote_increment`display_name`status`margin_enabled`status_message`min_market_funds`max_market_funds`post_only`limit_only`cancel_only`accessible!"SSSFFFFSSbCFFbbbb";
  products: scm[cols res] .ut.cast/: res;
  products: `sym xkey @[products;`sym;:;.Q.id'[products`id]];
  products};

///
// Get 24 hr stats for the product
//
// example:
// q) .mkt.getProduct24hrStats[`BTCUSD]
// q) .mkt.getProduct24hrStats["BTC-USD"]
//
// parameters:
// sym [symbol/string] - ccy pair/product
//
// returns:
// stats [dict(symbol|float)] - 24 hour stats, volume in base currency units
//  open        | 3592.71
//  high        | 3614.38
//  low         | 3550
//  volume      | 7785.109
//  last        | 3576.97
//  volume_30day| 239460.2
//
// wraps: get_product_24hr_stats
//  api - https://docs.pro.coinbase.com/#get-24hr-stats
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/qoinbase/public_client.py#L216
.mkt.getProduct24hrStats:{[sym]
  pid: .ref.getPID[sym];
  res: .mkt.CLI.get_product_24hr_stats[pid];
  stats: "F"$/:res;
  stats};

///
// Historic rates for a product.
// Rates are returned in grouped buckets based on requested granularity.
// 
// ** CAUTION ** Historical rates should not be polled frequently. 
// If you need real-time information, use the trade and book endpoints along with the websocket feed.
//
// example:
// q) .mkt.getProductHistoricRates[`BTCUSD; `; `; `] (defaults 1 min candles, ending now, 350 data points)
// q) .mkt.getProductHistoricRates[`BTCUSD; 2018.04.01T08:00:00.000; 2018.04.01T09:00:00.000; 60]
// 
// note:
// This request does not work well in the sandbox env, your mileage may vary.
//
// parameters:
// sym         [symbol/string]         - ccy pair/product
// start       [datetime/timestamp] - start time            (optional)
// end         [datetime/timestamp] - end time              (optional)
// granularity [int]                - time slice in seconds (optional)
//  - accepted granularity: (60, 300, 900, 3600, 21600, 86400)
//  - optional parameters can accept any null value
//
// returns:
// rates [table] - historic candle data, volume in base currency units
//  c     | t f a k e
//  ------| ---------
//  time  | z       2019.02.12T06:18:00.000
//  low   | f       3575.27
//  high  | f       3576.51
//  open  | f       3575.75
//  close | f       3575.28
//  volume| f       8.51
//
// wraps: get_product_historic_rates
//  api - https://docs.pro.coinbase.com/#get-historic-rates
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/qoinbase/public_client.py#L162
.mkt.getProductHistoricRates:{[sym;start;end;granularity];
  pid: .ref.getPID[sym];
  kwargs: `start`end`granularity!(3#.py.none);
  switch: not .ut.isNull each (start; end; granularity);
  if[switch 0;
    kwargs[`start]:.ut.q2iso start];
  if[switch 1;
    kwargs[`end]:.ut.q2iso end];
  if[switch 2;
    kwargs[`granularity]:granularity];
  res: .mkt.CLI.get_product_historic_rates[pid; pykwargs kwargs];
  rates: `time`low`high`open`close`volume!flip "zfffff"$/:.[res; (::; 0); .ut.epo2Q];
  flip rates};

///
// List the trades for a product.
//
// example:
// q) .mkt.getProductTrades[`BTCUSD; `; `; `] (defaults to latest trades)
// q) .mkt.getProductTrades[`BTCUSD; 5; 100; `]
// 
// note:
// This request does not work well in the sandbox env, your mileage may vary.
//
// parameters:
// sym    [symbol/string] - ccy pair/product
// before [int] - begin trade index (optional)
// after  [int] - end trade index   (optional)
// limit  [int] - number of records (optional)
//  - under 100, anything higher auto paginated, arg is finicky
//
// returns:
// trades [table] - trades within index, defaults to latest
//  c       | t f a k e
//  --------| ---------
//  time    | z       2014.12.02T11:05:40.382
//  trade_id| j       59109686
//  price   | f       3568.23
//  size    | f       0.00245077
//  side    | s       `sell
//
// wraps: get_product_trades
//  api - https://docs.pro.coinbase.com/#get-trades
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/qoinbase/public_client.py#L118
.mkt.getProductTrades:{[sym;before;after;limit];
  pid:.ref.getPID[sym];
  kwargs: `before`after`limit!(3#.py.none);
  switch: not .ut.isNull each (before; after; limit);
  if[switch 0;
    kwargs[`before]:before];
  if[switch 1;
    kwargs[`after]:after];
  if[switch 2;
    if[limit<100;
      kwargs[`limit]:limit]];
  res: .mkt.CLI.get_product_trades[pid; pykwargs kwargs];
  trades: .py.list[res];
  trades: $[.ut.isStr last trades; -1_;]trades;
  trades: @[trades; `time; {.ut.iso2Q'[x]}];
  trades: "zjFFS"$/:trades;
  trades};

///
// Snapshot about the last trade (tick), best bid/ask and 24h volume
//
// **CAUTION** Polling is discouraged in favor of connecting via the websocket stream and listening for match messages.
//
// example:
// q) .mkt.getProductTicker[`BTCUSD]
// q) .mkt.getProductTicker["BTC-USD"]
//
// parameters:
// sym    [symbol/string] - ccy pair/product
//
// returns:
// tick [dict(symbol|mixed)] - ticker info
//  trade_id| 59109835j
//  price   | 3563.57f
//  size    | 0.0759458f
//  time    | 2019.02.12T09:33:35.208z
//  bid     | 3563.18f
//  ask     | 3563.19f
//  volume  | 7877.695f
//
// wraps: get_product_ticker
//  api - https://docs.pro.coinbase.com/#get-product-ticker
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/qoinbase/public_client.py#L93
.mkt.getProductTicker:{[sym]
  pid: .ref.getPID[sym];
  tick: .mkt.CLI.get_product_ticker[pid];
  tick: "jFFZFFF"$tick;
  tick};

///
// Get the API server time
//
// wraps: get_time
// api - https://docs.pro.coinbase.com/#time
// lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/qoinbase/public_client.py#L254
//
// parameters:
// fmt [symbol] - format toe receive timestamp in (iso, epoch, q)
//
// returns:
// tm [dict] - server time in ISO, epoch, and q format
//  - (symbol->mixed)
//  - example
//    iso   | "2019-02-12T09:37:23.973Z"
//    epoch | 1.549964e+09
//    qt    | 2019.02.12T09:37:23.973
.mkt.getTime:{[fmt] 
  tm: .mkt.CLI.get_time[];

  if[.ut.isNull fmt; :.ut.epo2Q tm`epoch]; 

  .ut.assert[fmt in `iso`epoch`qt`all;"Bad format"]; 

  tm[`qt]:.ut.epo2Q tm`epoch; 

  if[fmt=`all; :tm]; 

  tm[fmt]};

///
// Get a list of open orders for a product.
//
// wraps: get_product_order_book
// api - https://docs.pro.coinbase.com/#get-product-order-book
// lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/qoinbase/public_client.py#L53
//
// parameters:
// sym   [symbol/string] - ccy pair/product
// level [int]           - book level (optional) default=1
//
// note:
// The amount of detail shown can be customized with the `level`
//  levels:
//    1: Only the best bid and ask
//    2: Top 50 bids and asks (aggregated)
//    3: Full order book (non aggregated)
//  Level 1 and Level 2 are recommended for polling. For the most
//  up-to-date data, consider using the websocket stream.
//
// returns:
// book [dict] - list of bid, ask orders (price; size; num-orders) at requested level
//  - (symbol->mixed)
//  - example
//    sequence| 603223 
//    bids    | ,("0.031";"3.76039452";1)
//    asks    | ,("0.98999";"16703.58801245";6)
.mkt.getProductOrderBook:{[sym;level]
  pid: .ref.getPID[sym];
  book: .mkt.CLI.get_product_order_book[pid; level];
  cast: $[level<3;"FFj";"FFG"];
  book: @[book; `bids; cast$/:];
  book: @[book;`asks; cast$/:];
  book};




.ord.placeMarketOrder[`BTCUSD;`buy;0.001]

.ord.placeMarketOrder[`BTCUSD;`sell;10]
.ord.placeLimitOrder[`BTCUSD;`buy;0.02;0.1]
r:.mkt.getProductOrderBook[`BTCUSD;3]
r`bids
r`asks
1113f073-d036-4796-8e98-a98d8597e5f6 ETH      999999.7 999999.7  0    7645849f-1de8-46df-af97-38865f0e3876
b005a81d-6506-4d07-9e90-518224497160 BTC      999874.2 999874.2  0    7645849f-1de8-46df-af97-38865f0e3876
\c 500 500
cba[]
.ord.CLI.coinbase_deposit[10.00;`USD;"1b4b4fbc-8071-5e7c-b36e-a1c589a2cf20"]
.ord.CLI.get_coinbase_accounts[]
.ord.CLI.get_payment_methods[][1]
.ord.CLI.deposit["210.00";"USD";"e49c8d15-547b-464e-ac3d-4b9d20b360ec"]
cba:.ord.CLI.get_coinbase_accounts[]
cba[4]
f263ca75-4db0-4cd9-bd6f-3bbd873d1c5a
.ord.getFills[`BTCUSD;`;`]
.ord.getAccountHistory[`USD;`]
.ord.getFills[`BTCUSD;`;`]

///////////////////////////////////////
// REFERENCE DATA                    //
///////////////////////////////////////

///
// Initialize reference data
.ref.cache.mkt:{[]
  // Currency data
  .ref.ccy: .mkt.CLI.getCurrencies[];
  // Product data
  .ref.products: .mkt.CLI.getProducts[];
  
  .ref.ccyList: exec id from .ref.ccy;
  
  .ref.symList: exec sym from .ref.products;
  
  .ref.pidList: exec id from .ref.products;
  };

///
// Initialize reference data
.ref.cache.ord:{[]
  .ref.accounts: .ord.getAccounts[];
  };

///
// Gets correct productID format
//
// parameters:
// x [symbol/string] - ccy pair/product
//  (`BTCUSD; "BTCUSD"; `$"BTC-USD"; "BTC-USD")
//
// returns:
// x [sym] - formatted productID (`BTC-USD)
.ref.getPID:{s:.Q.id $[.ut.isStr x; `$; ]x; .ref.products[s; `id]};

///
// Resolves accountID by currency or ID
//
// parameters:
// x [symbol/string] - ccy or accountID
.ref.getAccID:{[x]
  id: $[.ut.isSym x;
        (x; ?[.ref.accounts; enlist(=; `currency; enlist x); (); ()]`id)(x in .ref.ccyList);
          .ut.isStr x; x; string x];
  id};

.ref.orderTemp: `id`price`size`product_id`side`type`time_in_force`post_only`created_at`done_at`done_reason`fill_fees`filled_size`executed_value`status`settled`funds`specified_funds`stop`stop_price`stp!"SFFSSSSb**SFFFSbFFSFS";
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

///
// List known currencies
//
// example:
// q) .mkt.getCurrencies[]
// q) .mkt.getCurrencies[1b]
// 
// parameters:
// v [boolean] - verbose, display more in-depth currency data (optional)
//
// returns:
// ccy [ktable] - currency reference data
//  c             | t f a k e
//  --------------| ---------
//  id            | s     y USD
//  name          | s       United States Dollar
//  min_size      | f       0.01
//  status        | s       `online
//  message       | c       ""
//  max_precision | f       0.01
//  convertible_to| s       ,`USDC
//
// wraps: get_currencies
//  api - https://docs.pro.coinbase.com/#get-currencies
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/qoinbase/public_client.py#L236
.mkt.getCurrencies:{[v]
  res: .scm.cast .cli.MKT.get_currencies[];
  ccy: 1!(`details,:) _ res;
  if[.ut.default[v]0b;
    dts: .scm.cast res`details;
    ccy: ccy,'dts;
  ];
  ccy};

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
  res: .cli.MKT.get_products[];
  p2: `sym xkey {@[x; `sym; :; .Q.id'[x`id]]}.scm.cast res;
  p2}

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
  res: .cli.MKT.get_product_24hr_stats[pid];
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
// q) .mkt.getProductHistoricRates[`BTCUSD] (defaults 1 min candles, ending now, 350 data points)
// q) .mkt.getProductHistoricRates[`BTCUSD; 60]
// q) .mkt.getProductHistoricRates[`BTCUSD; 900; 2018.04.01T08:00:00.000; 2018.04.01T09:00:00.000] 
// 
//
// parameters: *USES EXPANDABLE PARAMETERS*
// sym         [symbol/string]      - ccy pair/product
// granularity [int]                - time slice in seconds (expandable)
// start       [datetime/timestamp] - start time            (expandable)
// end         [datetime/timestamp] - end time              (expandable)
//  - accepted granularity: (60, 300, 900, 3600, 21600, 86400)
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
.mkt.getProductHistoricRates: .ut.xfunc {[x];
  productID: .ref.getPID .ut.xposi[x; 0; `sym];
  granularity: .ut.default[x 1; `];
  start:       .ut.default[x 2; `];
  end:         .ut.default[x 3; `];
  kwargs: .ut.kwargs.pop[`granularity`start`end; (::;.ut.q2iso;.ut.q2iso); (granularity;start;end)];
  res: .cli.MKT.get_product_historic_rates[pid; pykwargs kwargs];
  rates: `time`low`high`open`close`volume!flip "zfffff"$/:.[res; (::; 0); .scm.fn.epoch];
  flip rates};

///
// List the trades for a product.
//
// example:
// q) .mkt.getProductTrades[`BTCUSD] (defaults to latest trades)
// q) .mkt.getProductTrades[`BTCUSD;7447500;7447550]
// q) .mkt.getProductTrades[`BTCUSD;7447500;7447550;10]
// 
//
// parameters:
// sym    [symbol/string] - ccy pair/product
// before [int] - Begin trade index (expandable)
// after  [int] - End trade index   (expandable)
// limit  [int] - Number of results. Max 100 (expandable)
//
// *note* Cursor pagination can be unintuitive at first. 
// before and after cursor arguments should not be confused with before and after in chronological time. 
// Most paginated requests return the latest information (newest) as the first page sorted by newest (in chronological time) first. 
// To get older information you would request pages after the initial page. 
// To get information newer, you would request pages before the first page.
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
.mkt.getProductTrades:.ut.xfunc {[x]
  pid: .ref.getPID .ut.xposi[x; 0; `sym];
  b: .ut.default[x 1; .py.none];
  a: .ut.default[x 2; .py.none];
  l: .ut.default[x 3; .py.none];
  kwargs: .ut.kwargs.pop[`before`after`limit;(b;a;l)];
  res: .py.list .cli.MKT.get_product_trades[pid; pykwargs kwargs];
  trades: .scm.cast res;
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
// sym [symbol/string] - A valid product id or sym <.ref.p2`sym`id>
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
  tick: .scm.cast .cli.MKT.get_product_ticker[pid];
  tick};

///
// Get the API server time
//
// example:
// q) .mkt.getTime[]
// q) .mkt.getTime[`iso]
//
// wraps: get_time
// api - https://docs.pro.coinbase.com/#time
// lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/qoinbase/public_client.py#L254
//
// parameters:
// fmt [symbol] - Format timestamp output (q[default], iso, epoch, all)
//
// returns:
// tm [dict] - server time in ISO, epoch, and q format
//  - (symbol->mixed)
//  - example
//    iso   | "2019-02-12T09:37:23.973Z"
//    epoch | 1.549964e+09
//    qt    | 2019.02.12T09:37:23.973
.mkt.getTime:{[fmt] 
  tm: .cli.MKT.get_time[];
  def: .scm.fn[`epoch]tm`epoch;

  if[.ut.isNull fmt; :def];

  .ut.assert[fmt in `iso`epoch`q`all; "Invalid option - choose from: `iso`epoch`q`all"];

  res: $[fmt in `iso`epoch; tm fmt; fmt = `q; def; [tm[`q]:def; tm]]; 

  res};

///
// Get a list of open orders for a product.
//
// example:
// q) .mkt.getProductOrderBook[`BTCUSD;2]
//
// wraps: get_product_order_book
// api - https://docs.pro.coinbase.com/#get-product-order-book
// lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/qoinbase/public_client.py#L53
//
// parameters:
// sym [symbol/string]   - A valid product id or sym <.ref.p2`sym`id>
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
  book: .cli.MKT.get_product_order_book[pid; level];
  fmt: ("FF";`price`size),'(("j";"G");(`num;`id))@\:level=3;
  res: @[book; `bids`asks; flip fmt[1]!flip fmt[0]$/:];
  res};

///////////////////////////////////////
// REFERENCE DATA                    //
///////////////////////////////////////

///
// Initialize reference data
.ref.cache.mkt:{[]
  // Currency data
  .ref.ccy: .mkt.getCurrencies[];
  // Product data
  .ref.p2: .mkt.getProducts[];
  
  .ref.ccys: exec id from .ref.ccy;
  
  .ref.syms: exec sym from .ref.p2;
  
  .ref.pids: exec id from .ref.p2;
  };
  
///
// Initialize reference data
.ref.cache.ord:{[]
  .ref.cache.mkt[];
  .ref.accounts: .ord.getAccounts[];
  };

///
// Cast guid to string
// Useful in API, as underlying python doesn't like guid types
.ref.castID:{$[.ut.isGuid x;string;]x};

///
// Gets correct productID format
//
// parameters:
// x [symbol/string] - ccy pair/product
//  (`BTCUSD; "BTCUSD"; `$"BTC-USD"; "BTC-USD")
//
// returns:
// x [sym] - formatted productID (`BTC-USD)
.ref.getPID:{s:.Q.id $[.ut.isStr x; `$; ]x; .ref.p2[s; `id]};

///
// Resolves accountID by currency or ID
//
// parameters:
// x [symbol/string] - ccy or accountID
.ref.getAccID:{[x]
  id: $[.ut.isSym x;
        (x; ?[.ref.accounts; enlist(=; `currency; enlist x); (); ()]`id)(x in .ref.ccys);
          .ut.isStr x; x; string x];
  id};
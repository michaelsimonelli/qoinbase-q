\l extend.q
.py.import[`qoinbase];
.py.reflect[`qoinbase];

.cli.api_env:`live`test!("https://api.pro.coinbase.com";"https://api-public.sandbox.pro.coinbase.com");

.qb.api.cbpro.AUTH_ENV_VAR:`CB_ACCESS_KEY`CB_ACCESS_SIGN`CB_ACCESS_PASSPHRASE;

api_key: getenv `CBPRO_ACCESS_KEY`CBPRO_ACCESS_SIGN`CBPRO_ACCESS_PASSPHRASE

.cli.public:{[env]
  api_url: `$.cli.api_env[env];
  client: .qoinbase.PublicClient[api_url];
  client};

.cli.auth:{[env;api_key]
  api_url: `$.cli.api_env[env];
  api_key: {if[not (.ut.isSym x) or (.ut.isStr x); 
              '"Api_key args must be symbol or string"];
              $[.ut.isStr x; `$;]x} each api_key;
  args: api_key,api_url;
  client: .qoinbase.AuthenticatedClient[args];
  client};

pc
pc:.cli.public[`live];
ac:.cli.auth[`test];

.qb.api.cbpro.cli.create0:{[l]
  chk1: any (abs type@'l) in\: 11 10h;
  chk2: (l 0) in key .qb.cfg.cbpro.cli;
  .ut.assert[chk1 and chk2;"Error: Invalid Argument"];

  class: l 0;
  mapping: .qb.cfg.cbpro.cli[class; `mapping];
  service: .qb.cfg.cbpro.cli[class; `service];
  xenv_env: .qb.cfg.glb.xenv[.qb.XENV; service];
  endp_env: .ut.defn[l 1;  xenv_env];
  auth_arg: .ut.defn[l 2; `fromEnv];
  endp_url: .qb.cfg.cbpro.api[service; endp_env];

  args: $[class=`public;
          endp_url;
          [
            api_key: $[not `fromEnv ~ auth_arg; auth_arg;
                        [
                          authEV: .app.params.get[`cbpro] .qb.api.cbpro.AUTH_ENV_VAR;
        
                            if[count missEV: where .ut.isNull each authEV;
                              '"Error: Missing cbpro auth env vars (",(", " sv string missEV),")"];
        
                          authEV
                        ]
                      ];
            api_key,endp_url
          ]
        ];

  client: .qoinbase[mapping][args];

  attrb: (key client[`docs_]) except `;
  names: key@/:client[`docs_][attrb];
  valus: client@/:names;

  client,: (!/)(attrb;(!/)@'flip(names;valus));
  client: raze/[names] _ client;

  apiFun: (!/) .ut.enlist each (`config;.qb.api.cbpro.cli[`config]@(client));
  apiRef: `typ`env`ins`cxt!(class,endp_env,client[`ins`cxt]);
  apiCxt: apiFun,apiRef;

  client[`cli]:apiCxt;
  @[client[`cxt]; key apiRef; :; value apiRef];
  
  client: (key apiCxt) _ client;
  client};

.qb.api.cbpro.cli.create:.ut.overload[.qb.api.cbpro.cli.create0];

.qb.api.cbpro.cli.config:{[px;pa]
  cfg: (`typ`env`ins`cxt`url)!(`;`;`;`;"");
  cxt: px[`cxt];
  cfg[`typ`env]:cxt`typ`env;
  cfg[`ins`cxt]:cxt`ins`cxt;
  cfg[`url]:px[`vars;`url][];
  cfg};


.app.import[`ref];

///////////////////////////////////////
// PUBLIC MARKET DATA FUNCS          //
///////////////////////////////////////
//
// Few simple utility and accessibility functions for exploring 
// the basics of the underlying library and q integration.
//
// * For documentation and full functionality of the underlying library
// see: https://github.com/michaelsimonelli/qoinbase-python
//
// * For the full coinbase pro API documentation
// see: https://docs.pro.coinbase.com/
// ____________________________________________________________________________

///
// Public Client
// The Public Client is essentially a public market data client.
// The functions provided are wrappers around the underlying library.
// It makes the API a bit more accessible in q and user friendly.
// The wrappers are just examples, feel free to tweak.
// *NOTE*
//  - Requires .cb.PC to be initialized
//  - This client is pointed at the live api endpoint, the sandbox endpoint
//    still has several kinks and is not as reliable when accessing market data
//  - As the public client is not authenticated, it does not provide execution
//    capabilities, but be aware this is a live endpoint
// ____________________________________________________________________________

///
// List known currencies
//
// wraps: get_currencies
// api - https://docs.pro.coinbase.com/#get-currencies
// lib - https://github.com/michaelsimonelli/qoinbase-python/blob/master/qoinbase/public_client.py#L236
// 
// note:
// The fields (message and details) are stripped from raw result,
// as 'message' consistently (always in my experience) returns null and 'details' is a bit superfluous for this example.
// However, the field 'type' is extracted from 'details' to display some extra info.
//
// returns:
// ccy [ktable] - currency reference data
//  - example:
//    c             | t f a k e
//    --------------| ---------
//    id            | s     y USD
//    name          | s       United States Dollar
//    min_size      | f       0.01
//    status        | s       `online
//    convertible_to| S       ,`USDC
//    typ           | s       `fiat
.qb.api.cbpro.mkt.getCurrencies:{[px;pa]
  res: px[`get_currencies](::);
  ccy: (uj/)(enlist each `message`details _/: res);
  ccy[`typ]:{x[`details]`type} each res;
  ccy: 1!"SSFSSS"$/:ccy;
  ccy};

///
// Get a list of available currency pairs for trading
//
// wraps: get_products
// api - https://docs.pro.coinbase.com/#get-products
// lib - https://github.com/michaelsimonelli/qoinbase-python/blob/master/qoinbase/public_client.py#L33
//
// note:
// The fields (satus_message and accessible) are stripped from raw result,
// as 'status_message' consistently (always in my experience) returns null 
// and 'accessible' is NOT consistently included in result set. 
// Also, not completely clear on the definition of 'accessible', as its value changes fairly sporadicly
// (tips on reliable definition welcome - not present in api docs)
//
// returns:
// products [ktable] - product reference data
//  - keyed on sym rather than id (`BTCUSD vs `BTC-USD), just out of preference,
//  as sym is more accessible IMO, feel free to change
//  - example:
//    c             | t f a k e
//    --------------| ---------
//    sym             | s   y `BTCUSD
//    id              | s     `BTC-USD
//    base_currency   | s     `BTC
//    quote_currency  | s     `USD
//    base_min_size   | f     0.001
//    base_max_size   | f     70f
//    quote_increment | f     0.01
//    display_name    | s     `BTC/USD
//    status          | s     `online
//    margin_enabled  | b     0b
//    min_market_funds| f     10f
//    max_market_funds| f     1000000f
//    post_only       | b     0b
//    limit_only      | b     0b
//    cancel_only     | b     0b
.qb.api.cbpro.mkt.getProducts:{[px;pa]
  res: px[`get_products](::);
  products: "SSSFFFSSbFFbbb"$/:`status_message`accessible _/: res;
  products: `sym xkey @[products;`sym;:;.Q.id'[products`id]];
  products};

///
// Get 24 hr stats for the product
//
// wraps: get_product_24hr_stats
// api - https://docs.pro.coinbase.com/#get-24hr-stats
// lib - https://github.com/michaelsimonelli/qoinbase-python/blob/master/qoinbase/public_client.py#L216
//
// parameters:
// sym [symbol/string] - ccy pair/product
//
// returns:
// stats [dict] - 24 hour stats, volume in base currency units
//  - (symbol->float)
//  - example
//    open        | 3592.71
//    high        | 3614.38
//    low         | 3550
//    volume      | 7785.109
//    last        | 3576.97
//    volume_30day| 239460.2
.qb.api.cbpro.mkt.getProduct24hrStats:{[px;sym]
  pid: .ref.getPID[sym];
  res: px[`get_product_24hr_stats; pid];
  stats: "F"$/:res;
  stats};

///
// Historic rates for a product
// (see api & lib doc for in-depth details)
// **Caution** Polling historic rates is discouraged, use trade endpoint or websocket stream feed
//
// wraps: get_product_historic_rates
// api - https://docs.pro.coinbase.com/#get-historic-rates
// lib - https://github.com/michaelsimonelli/qoinbase-python/blob/master/qoinbase/public_client.py#L162
//
// example:
// > .qb.api.getProductHistoricRates[`BTCUSD; `; `; `] (defaults 1 min candles, ending now, 350 data points)
// > .qb.api.getProductHistoricRates[`BTCUSD; 2018.04.01T08:00:00.000; 2018.04.01T09:00:00.000; 60]
//
// parameters:
// sym         [symbol/string]      - ccy pair/product
// start       [datetime/timestamp] - start time            (optional)
// end         [datetime/timestamp] - end time              (optional)
// granularity [int]                - time slice in seconds (optional)
//  - accepted granularity: (60, 300, 900, 3600, 21600, 86400)
//  - optional parameters can accept any null value
//
// returns:
// rates [table] - historic candle data, volume in base currency units
//  - example:
//    c     | t f a k e
//    ------| ---------
//    time  | z       2019.02.12T06:18:00.000
//    low   | f       3575.27
//    high  | f       3576.51
//    open  | f       3575.75
//    close | f       3575.28
//    volume| f       8.51
.qb.api.cbpro.mkt.getProductHistoricRates:{[px;sym;start;end;granularity];
  pid: .ref.getPID[sym];
  kwargs: `start`end`granularity!(3#.py.none);
  switch: not .ut.isNull each (start; end; granularity);
  if[switch 0;
    kwargs[`start]:.ut.q2ISO start];
  if[switch 1;
    kwargs[`end]:.ut.q2ISO end];
  if[switch 2;
    kwargs[`granularity]:granularity];
  res: px[`get_product_historic_rates][pid; pykwargs kwargs];
  rates: `time`low`high`open`close`volume!flip "zfffff"$/:.[res; (::; 0); .ut.epoch2Q];
  flip rates};

///
// List the trades for a product.
// (see api & lib doc for in-depth details)
//
// wraps: get_product_trades
// api - https://docs.pro.coinbase.com/#get-trades
// lib - https://github.com/michaelsimonelli/qoinbase-python/blob/master/qoinbase/public_client.py#L118
//
// example:
// > .qb.api.getProductTrades[`BTCUSD; `; `; `] (defaults to latest trades)
// > .qb.api.getProductTrades[`BTCUSD; 5; 100; `]
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
//  - example:
//    c       | t f a k e
//    --------| ---------
//    time    | z       2014.12.02T11:05:40.382
//    trade_id| j       59109686
//    price   | f       3568.23
//    size    | f       0.00245077
//    side    | s       `sell
.qb.api.cbpro.mkt.getProductTrades:{[px;sym;before;after;limit];
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
  res: px[`get_product_trades][pid; pykwargs kwargs];
  trades: .py.builtins.list[res];
  trades: $[.ut.isStr last trades; -1_;]trades;
  trades: @[trades; `time; {.ut.iso2Q'[x]}];
  trades: "zjFFS"$/:trades;
  trades};

///
// Snapshot about the last trade (tick), best bid/ask and 24h volume
// **Caution** Polling the ticker is discouraged, for real-time data use websocket feed
//
// wraps: get_product_ticker
// api - https://docs.pro.coinbase.com/#get-product-ticker
// lib - https://github.com/michaelsimonelli/qoinbase-python/blob/master/qoinbase/public_client.py#L93
//
// parameters:
// sym    [symbol/string] - ccy pair/product
//
// returns:
// tick [dict] - ticker info
//  - (symbol->mixed)
//  - example
//    trade_id| 59109835j
//    price   | 3563.57f
//    size    | 0.0759458f
//    time    | 2019.02.12T09:33:35.208z
//    bid     | 3563.18f
//    ask     | 3563.19f
//    volume  | 7877.695f
.qb.api.cbpro.mkt.getProductTicker:{[px;sym]
  pid: .ref.getPID[sym];
  res: px[`get_product_ticker][pid];
  tick: .cb.PC.get_product_ticker[pid];
  tick: "jFFZFFF"$tick;
  tick};

///
// Get the API server time
//
// wraps: get_time
// api - https://docs.pro.coinbase.com/#time
// lib - https://github.com/michaelsimonelli/qoinbase-python/blob/master/qoinbase/public_client.py#L254
//
// parameters:
// f [symbol] - format toe receive timestamp in (iso, epoch, q)
//
// returns:
// tm [dict] - server time in ISO, epoch, and q format
//  - (symbol->mixed)
//  - example
//    iso   | "2019-02-12T09:37:23.973Z"
//    epoch | 1.549964e+09
//    qiso  | 2019.02.12T09:37:23.973
//    qepoch| 2019.02.12T09:37:23.973
.qb.api.cbpro.mkt.getTime:{[px;f]
  .ut.assert[f in `i`e`qi`qe`all;"Bad format"];
  tm: px[`get_time](::);
  tm,:`qi`qe!(.ut.iso2Q tm`iso; .ut.epoch2Q tm`epoch)
  if[f=`all; :tm];
  tm[f]};


///
// Get a list of open orders for a product.
//
// wraps: get_product_order_book
// api - https://docs.pro.coinbase.com/#get-product-order-book
// lib - https://github.com/michaelsimonelli/qoinbase-python/blob/master/qoinbase/public_client.py#L53
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
.qb.api.cbpro.mkt.getProductOrderBook:{[px;sym;level]
  pid: .ref.getPID[sym];
  book: px[`get_product_order_book][pid; level];
  cast: $[level<3;"FFj";"FFG"];
  book: @[book; `bids; cast$/:];
  book: @[book;`asks; cast$/:];
  book};


.mkt.map.cxt:{[cli]
  mktApi: .qb.api.cbpro.mkt;

  mktFns: (key mktApi) except ``init;

  mktCxt: (!/) .ut.enlist each (::;mktApi@\:cli[`func])@\:mktFns;

  cli: @[cli; `mkt; :; mktCxt];

  cli};

  
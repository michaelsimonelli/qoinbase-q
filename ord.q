///////////////////////////////////////
// EXECUTION API                     //
///////////////////////////////////////
//
// Private, authenticated endpoints for order and account management.
//
// * For documentation and full functionality of the underlying library
// see: https://github.com/michaelsimonelli/qoinbase-py
//
// * For the full coinbase pro API documentation
// see: https://docs.pro.coinbase.com/
// ____________________________________________________________________________

///
// Get a list of trading accounts.
//
// When you place an order, the funds for the order are placed on
// hold. They cannot be used for other orders or withdrawn. Funds
// will remain on hold until the order is filled or canceled. The
// funds on hold for each account will be specified.
//
// example:
// q) .ord.getAccounts[]
//
// returns:
// accounts [table] - Info about all accounts
//  c         | t f a k e
//  ----------| ---------
//  id        | g       00000000-0000-0000-0000-000000000000
//  currency  | s       `BAT
//  balance   | f       1000000f
//  available | f       1000000f
//  hold      | f       0f
//  profile_id| g       00000000-0000-0000-0000-000000000000
//  trading_enabled| 1b
//
// wraps: get_currencies
//  api - https://docs.pro.coinbase.com/#list-accounts
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L58
.ord.getAccounts:{[]
  res: .cli.ORD.get_accounts[];
  accounts: .scm.cast res;
  accounts};

///
// Information for a single account. Request by account_id or ccy.
//
// example:
// q) .ord.getAccount[`USD]
// q) .ord.getAccount["00000000-0000-0000-0000-000000000000"]
//
// parameters:
// x  [symbol/string] - account_id or currency of account to get data from
//
// returns:
// account [dict] - Account information
//  id        | 00000000-0000-0000-0000-000000000000
//  currency  | `USD
//  balance   | 999.1795f
//  available | 999.1795f
//  hold      | 0f
//  profile_id| 00000000-0000-0000-0000-000000000000
//
// wraps: get_currencies
//  api - https://docs.pro.coinbase.com/#get-an-account
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L37
.ord.getAccount:{[x]
  id: .ref.castID .ref.getAccID x;
  res: .cli.ORD.get_account[id]; if[`message in key res; 'res`message];
  account: .scm.cast res;
  account};

///
// List account activity. Account activity either increases or
// decreases your account balance.
//
// example:
// q) .ord.getAccountHistory[`USD;`fee;`]
// q) .ord.getAccountHistory["00000000-0000-0000-0000-000000000000";`fee;1b]
//
// parameters:
// x  [symbol/string/guid] - AccountID or CCY of account to get data from
// t  [symbol]             - Filter by transaction type, defaults to all. see docs for list
// v  [boolean]            - Verbose output of account details
//
// returns:
// ach [table] - History information for the account
// c         | t f a k e                                                                                      
// ----------| ----------
// created_at| z       2018.03.06T09:04:31.766                                                                
// id        | j       30631158                                                                               
// amount    | f       -0.2991027                                                                             
// balance   | f       99900f                                                                                 
// type      | s       `fee                                                                                   
// details   |         `order_id`trade_id`product_id!("a1b2c3d4";"3109";"ETH-USD")
//
// wraps: get_account_history 
//  api - https://docs.pro.coinbase.com/#get-account-history
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L86
.ord.getAccountHistory:{[x;t;v]
  id: .ref.castID .ref.getAccID x;
  res: .py.list .cli.ORD.get_account_history id;

  if[not .ut.isNull t;
    f:{x like string y}[res`type;];
    res@:where max f'[.ut.enlist t];
  ];

  ach: .scm.cast (`details,:) _ res;
  
  if[.ut.default[v]0b;
    ach: ach,'.scm.cast res`details;
  ];

  ach};

///
// Get holds on an account.
//
// example:
// q) .ord.getAccountHolds[`USD]
// q) .ord.getAccountHolds["a1b2c3d4"]
//
// parameters:
// x  [symbol/string/guid] - AccountID or CCY of account to get data from
//
// returns:
// holds [table] - Hold information for the account
//  c         | t f a k e                                   
//  ----------| --------------------------------------------
//  created_at| z       2019.04.27T15:53:33.419             
//  id        | g       0188f05a-1e6a-473e-95a3-c48810cdf513
//  amount    | f       24.51051                            
//  type      | s       `order                              
//  ref       | g       b1e2f467-87e5-4c84-96b9-0b656dd18d4d
//
// wraps: get_account_holds
//  api - https://docs.pro.coinbase.com/#get-holds
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L125
.ord.getAccountHolds:{[x]
  id: .ref.castID .ref.getAccID x;
  res: .py.list .cli.ORD.get_account_holds[id];
  holds: .scm.cast res;
  holds};

///
// Get a list of recent fills.
//
// example:
// q) .ord.getFills[`BTCUSD]
// q) .ord.getFills["BTCUSD";3634376]
// q) .ord.getFills["00000000-0000-0000-0000-000000000000";3634376]
// q) .ord.getFills[`BTCUSD;"G"$"00000000-0000-0000-0000-000000000000";3571412]
//
// parameters:
// sym     [symbol/string] - Limit list to this productID. Accepts valid and simple forms: (`BTCUSD; "BTC-USD").
// orderID [symbol/string/guid] - Limit list to this orderID.
// before  [long] - Fetch all trades with greater trade_id (newer fills).
//
// *note* Requests without either sym or orderID will be rejected.
//
// returns:
// flls [table] - List of fills
//  c         | t f a k e                                   
//  ----------| --------------------------------------------
//  created_at| z       2019.04.15T11:05:08.397             
//  trade_id  | j       3214117                             
//  product_id| s       `BTC-USD                            
//  order_id  | g       00000000-0000-0000-0000-000000000000
//  user_id   | s       `abcdef123          
//  profile_id| g       00000000-0000-0000-0000-000000000000
//  liquidity | c       "M"                                 
//  price     | f       0.02                                
//  size      | f       0.001                               
//  fee       | f       0f                                  
//  side      | s       `sell                               
//  settled   | b       1b                                  
//  usd_volume| f       2e-05   
//
// wraps: get_fills
//  api - https://docs.pro.coinbase.com/#list-fills
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L578
.ord.getFills: .ut.xfunc {[x]
  arg: `product_id`order_id`before!(3#.py.none);
  fn:{if[all .ut.toStr[y] in .Q.n; x[`before]:y];
      if[36=count .ut.toStr[y];x[`order_id]:.ref.castID y];
      if[not .ut.isNull p:.ref.getPID y; x[`product_id]:p];x};
  arg: fn/[arg;x];
  res: .py.list .cli.ORD.get_fills[pykwargs arg];
  if[.ut.isNull res; :res];
  flls: .scm.cast res;
  flls};

///
// List your current open orders.
//
// example:
// q) .ord.getOrders[`BTCUSD]
// q) .ord.getOrders[`BTCUSD;`active]
// q) .ord.getOrders[`BTCUSD;`active`open]
// q) .ord.getOrders[`done]
//
// parameters:
// sym    [symbol/string] - ProductID. Accepts valid and simple forms: (`BTCUSD; "BTC-USD")
// status [symbol/string] - Limit list of orders to this status or statuses. (`active; `open; `pending)
//
// *NOTE* Function is overloaded, non-dependent argument count/position.
//
// returns:
// ords [table] - List of orders
//  c              | t f a k e                                    
//  ---------------| ---------------------------------------------
//  id             | g       3c1ed9d7-43b5-4844-8b9c-c4a0a2eca76a
//  size           | f       0n                                   
//  product_id     | s       `ETH-USD                             
//  side           | s       `buy                                 
//  type           | s       `market                              
//  post_only      | b       0b                                   
//  created_at     | z       2018.03.06T09:04:31.741              
//  done_at        | z       2018.03.06T09:04:31.760              
//  done_reason    | s       `filled                              
//  fill_fees      | f       0.2991027                            
//  filled_size    | f       0.1157966                            
//  executed_value | f       99.70089                             
//  status         | s       `done                                
//  settled        | b       1b                                   
//  funds          | f       99.7009                              
//  specified_funds| f       100f                                 
//  price          | f       0n                                   
//  time_in_force  | s       `                                    
//  stop           | s       `                                    
//  stop_price     | f       0n    
//  
// wraps: get_orders
//  api - https://docs.pro.coinbase.com/#list-orders
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L513
.ord.getOrders: .ut.xfunc {[x]
  arg: `product_id`status!(2#.py.none);
  fn:{if[any y in`active`open`pending`done`settled; x[`status]:y];
      if[.ut.isAtom y; if[not .ut.isNull p:.ref.getPID y; x[`product_id]:p]];x};
  arg: fn/[arg;x];
  res: .py.list .cli.ORD.get_orders[pykwargs arg];
  if[not count res; :(::)];
  ord: .scm.cast res;
  ord};

///
// Get a single order by order id.
//
// example:
// q) .ord.getOrder[00000000-0000-0000-0000-000000000000]
//
// parameters:
// orderID [symbol/string/guid] - The order to get information of.
//
// returns:
// ords [dict] - Order information
//  id            | 00000000-0000-0000-0000-000000000000
//  price         | 100f
//  size          | 0.01
//  product_id    | `BTC-USD
//  side          | `buy
//  type          | `limit
//  time_in_force | `GTC
//  post_only     | 0b
//  created_at    | 2019.05.15T08:29:17.078
//  done_at       | 2019.05.16T09:33:12.539
//  done_reason   | `filled
//  fill_fees     | 0f
//  filled_size   | 0.01
//  executed_value| 1f
//  status        | `done
//  settled       | 1b
//  
// wraps: get_order
//  api - https://docs.pro.coinbase.com/#list-orders
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L478
.ord.getOrder:{[orderID]
  res: .cli.ORD.get_order[.ref.castID orderID];
  ord: .scm.cast res;
  ord};

///
// Place market order.
//
// example:
// q) .ord.placeMarketOrder[`BTCUSD;`sell;0.01]
// q) .ord.placeMarketOrder[`BTCUSD;`sell;(enlist`funds)!enlist 100]
//
// parameters:
// sym  [symbol/string] - ProductID. Accepts valid and simple forms: (`BTCUSD; "BTC-USD")
// side [symbol/string] - Order side ('buy' or 'sell)
// size   [float] - Desired amount in crypto. Specify this or `funds` in kwargs.
// kwargs [dict] - Keyword arguments
//
// *NOTE* `size` and `kwargs` are overloaded based on type;
//        <float> sets the `size` parameter
//        <dict> sets `kwargs`
//        `funds` must be provided in kwargs.
//        Setting `size` defaults the remaining parameters.
//        Use `kwargs` for more granular customization.
//
// returns:
// ord [dict] - Order information
//  id            | `00000000-0000-0000-0000-000000000000
//  size          | 0.01
//  product_id    | `BTC-USD
//  side          | `sell
//  stp           | `dc
//  type          | `market
//  post_only     | 0b
//  created_at    | 2019.05.22T10:45:12.097
//  fill_fees     | 0f
//  filled_size   | 0f
//  executed_value| 0f
//  status        | `pending
//  settled       | 0b
//  
// wraps: place_market_order
//  api - https://docs.pro.coinbase.com/#place-a-new-order
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L253
.ord.placeMarketOrder: .ut.xfunc {[x]
  sym:  .ut.xposi[x; 0; `sym];
  side: .ut.xposi[x; 1; `side];
  kwargs: .ut.default[x 2; .ord.marketKW];
  pid: .ref.getPID[sym];
  res: .cli.ORD.place_market_order . (pid; side; (::;pykwargs)[.ut.isDict kwargs] kwargs);
  if[`message in key res; :res];
  ord: .scm.cast res;
  ord};

///
// Place limit order.
//
// example:
// q) .ord.placeLimitOrder[`BTCUSD;`sell;20100.00;0.01]
// q) .ord.placeLimitOrder[`BTCUSD;`sell;20100.00;0.01;(enlist `time_in_force)!enlist`IOC]
// q) .ord.placeLimitOrder[`BTCUSD;`sell;20100.00;0.01;(`time_in_force`cancel_after`post_only)!(`GTT;`day;1b)]
//
// parameters:
// sym    [symbol/string] - ProductID. Accepts valid and simple forms: (`BTCUSD; "BTC-USD")
// side   [symbol/string] - Order side ('buy' or 'sell)
// price  [float] - Price per crypto.
// size   [float] - Amount in crypto.
// kwargs [dict] - Keyword arguments
//
// returns:
// ord [dict] - Order information
//  id            | `00000000-0000-0000-0000-000000000000
//  price         | 20100f
//  size          | 0.01
//  product_id    | `BTC-USD
//  side          | `sell
//  stp           | `dc
//  type          | `limit
//  time_in_force | `GTT
//  expire_time   | 2019.05.23T11:14:47.000
//  post_only     | 1b
//  created_at    | 2019.05.22T11:14:47.335
//  fill_fees     | 0f
//  filled_size   | 0f
//  executed_value| 0f
//  status        | `pending
//  settled       | 0b
//
// wraps: place_limit_order
//  api - https://docs.pro.coinbase.com/#place-a-new-order
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L294
.ord.placeLimitOrder: .ut.xfunc {[x]
  sym:   .ut.xposi[x; 0; `sym];
  side:  .ut.xposi[x; 1; `side];
  price: .ut.xposi[x; 2; `price];
  size:  .ut.xposi[x; 3; `size];
  kwargs: .ut.default[x 4; .ord.limitKW];
  pid: .ref.getPID[sym];
  res: .cli.ORD.place_limit_order[pid; side; price; size; pykwargs kwargs];
  if[`message in key res; :res];
  ord: .scm.cast res;
  ord};

///
// Place stop loss order.
// *Creates a limit order, stop market is not supported.
//
// example:
// q) .ord.placeStopLoss[`BTCUSD;3015.00;3000.00;0.01]
//
// parameters:
// sym    [symbol/string] - ProductID. Accepts valid and simple forms: (`BTCUSD; "BTC-USD")
// stop_price [float] - Sets trigger price for stop order.
// price  [float] - Price per crypto (limit).
// size   [float] - Amount in crypto.
// kwargs [dict] - Keyword arguments
//
// returns:
// ord [dict] - Order information
//  id            | `00000000-0000-0000-0000-000000000000
//  price         | 3000f
//  size          | 0.01
//  product_id    | `BTC-USD
//  side          | `sell
//  stp           | `dc
//  type          | `limit
//  time_in_force | `GTC
//  post_only     | 0b
//  created_at    | 2019.06.08T06:39:02.138
//  fill_fees     | 0f
//  filled_size   | 0f
//  executed_value| 0f
//  status        | `pending
//  settled       | 0b
//  stop          | `loss
//  stop_price    | 3015f
//
// wraps: place_stop_loss
//  api - https://docs.pro.coinbase.com/#place-a-new-order
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L350
.ord.placeStopLoss: .ut.xfunc {[x]
  sym:        .ut.xposi[x; 0; `sym];
  stop_price: .ut.xposi[x; 1; `stop_price];
  price:      .ut.xposi[x; 2; `price];
  size:       .ut.xposi[x; 3; `size];
  kwargs:     .ut.default[x 4; .ord.limitKW];
  pid: .ref.getPID[sym];
  res: .cli.ORD.place_stop_loss[pid; stop_price; price; size; pykwargs kwargs];
  if[`message in key res; :res];
  ord: .scm.cast res;
  ord};

.mkt.getProductTicker[`BTCUSD]
price   | 9860.06

///
// Place stop entry order.
// *Creates a limit order, stop market is not supported.
//
// example:
// q) .ord.placeStopEntry[`BTCUSD;5050.00;5100.00;0.01]
//
// parameters:
// sym    [symbol/string] - ProductID. Accepts valid and simple forms: (`BTCUSD; "BTC-USD")
// stop_price [float] - Sets trigger price for stop order.
// price  [float] - Price per crypto (limit).
// size   [float] - Amount in crypto.
// kwargs [dict] - Keyword arguments
//
// returns:
// ord [dict] - Order information
//  id            | `00000000-0000-0000-0000-000000000000
//  price         | 5100f
//  size          | 0.01
//  product_id    | `BTC-USD
//  side          | `buy
//  stp           | `dc
//  type          | `limit
//  time_in_force | `GTC
//  post_only     | 0b
//  created_at    | 2019.06.08T06:43:54.985
//  fill_fees     | 0f
//  filled_size   | 0f
//  executed_value| 0f
//  status        | `pending
//  settled       | 0b
//  stop          | `entry
//  stop_price    | 5050f
//
// wraps: place_stop_loss
//  api - https://docs.pro.coinbase.com/#place-a-new-order
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L410
.ord.placeStopEntry: .ut.xfunc {[x]
  sym:        .ut.xposi[x; 0; `sym];
  stop_price: .ut.xposi[x; 1; `stop_price];
  price:      .ut.xposi[x; 2; `price];
  size:       .ut.xposi[x; 3; `size];
  kwargs:     .ut.default[x 4; .ord.limitKW];
  pid: .ref.getPID[sym];
  res: .cli.ORD.place_stop_entry[pid; stop_price; price; size; pykwargs kwargs];
  if[`message in key res; :res];
  ord: .scm.cast res;
  ord};

.ord.cancelOrder:{[orderID]
  res: .cli.ORD.cancel_order[.ref.castID orderID];
  if[not .ut.isDict res; res:.ut.raze "G"$res];
  res};

.ord.cancelAll:{[sym]
  res: .cli.ORD.cancel_all[.ref.getPID sym];
  if[not .ut.isDict res; res:.ut.raze "G"$res];
  res};

.ord.getCoinbaseAccounts:{[]
  res:.cli.ORD.get_coinbase_accounts[];
  res:`id`name`balance`currency`type`primary`active`hold_balance`hold_currency#/:res;
  res:"GSFSSbbFS"$/:res;
  res};

.ord.testDeposit:{[ccy]
  if[not `test = .cli.ORD.getEnv[];'testEnvOnly];
  t: {?[.ord.getCoinbaseAccounts[];((=;`currency;enlist x);(>;`balance;0));();()]}ccy;
  .cli.ORD.coinbase_deposit . string t`balance`currency`id
  };
  
.ord.limitKW: .ut.repeat[`client_oid`stp`time_in_force`cancel_after`post_only`overdraft_enabled`funding_amount; .py.none];
.ord.marketKW: .ut.repeat[`size`funds`client_oid`stp`overdraft_enabled`funding_amount; .py.none];

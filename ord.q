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

// Order Management Client
.ord.CLI:();


.sim.exmp:{[t]mt:meta t;ks:keys t;et:exec from t;update k:?[c in ks;`y;`],e:et[c] from mt}

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
//
// wraps: get_currencies
//  api - https://docs.pro.coinbase.com/#list-accounts
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L57
.ord.getAccounts:{[]
  res: .ord.CLI.get_accounts[];
  accounts: "GSFFFG"$/:res;
  accounts};
0ng
///
// Information for a single account. Request by account_id or ccy.
//
// example:
// q) .ord.getAccount[`USD]
// q) .ord.getAccount["a1b2c3d4"]
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
  id: .ref.getAccID[x];
  res: .ord.CLI.get_account[id];
  account: $[`message in key res; 'res`message; "GSFFFG"$res];
  account};

///
// List account activity. Account activity either increases or
// decreases your account balance.
//
// Entry type indicates the reason for the account change.
// * transfer:   Funds moved to/from Coinbase to cbpro
// * match:      Funds moved as a result of a trade
// * fee:        Fee as a result of a trade
// * rebate:     Fee rebate as per our fee schedule
// * conversion: Funds converted between fiat currency and a stablecoin
//
// example:
// q) .ord.getAccountHistory[`USD;`fee]
// q) .ord.getAccountHistory["a1b2c3d4";`match]
//
// parameters:
// x  [symbol/string] - account_id or currency of account to get data from
// t  [sym] - type/reason for account change, filters results, returns all types if null
//
// returns:
// accHist [table] - History information for the account
// c         | t f a k e                                                                                      
// ----------| ----------
// created_at| z       2018.03.06T09:04:31.766                                                                
// id        | j       30631158                                                                               
// amount    | f       -0.2991027                                                                             
// balance   | f       99900f                                                                                 
// type      | s       `fee                                                                                   
// details   |         `order_id`trade_id`product_id!("a1b2c3d4";"3109";"ETH-USD")
//
// wraps: get_currencies
//  api - https://docs.pro.coinbase.com/#get-account-history
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L85
.ord.getAccountHistory:{[x;t]
  id: .ref.getAccID[x];
  res: $[.ut.isNull t; .ord.CLI.get_account_history id; .ord.CLI.get_account_history[id; `type pykw t]];
  accHist: .py.list[res];
  accHist: "ZjFFS*"$/:accHist;
  accHist};

///
// List trading related account activity.
// Filters account history where change reason is `match or `fee
//
// example:
// q) .ord.getAccountHistoryDetails[`USD]
// q) .ord.getAccountHistoryDetails["a1b2c3d4"]
//
// parameters:
// x  [symbol/string] - account_id or currency of account to get data from
//
// returns:
// accHist [table] - Detailed trading related history information for the account
//  c         | t f a k e                                    
//  ----------| ---------------------------------------------
//  created_at| z       2018.03.06T09:04:31.766              
//  id        | j       30631156                             
//  amount    | f       -99.70089                            
//  balance   | f       99900.3                              
//  type      | s       `match                               
//  order_id  | g       00000000-0000-0000-0000-000000000000
//  trade_id  | j       3109                                 
//  product_id| s       `ETH-USD  
//
// wraps: custom func
.ord.getAccountHistoryDetails:{[x]
  res: .ord.getAccountHistory[x;`];
  res: ?[res;(in;`type;`match`fee,:),:;0b;()];
  details: "GJS"$/:res`details;
  accHist: ((`details,:) _ res),'details;
  accHist};


///
// Get holds on an account.
//
// example:
// q) .ord.getAccountHolds[`USD]
// q) .ord.getAccountHolds["a1b2c3d4"]
//
// parameters:
// x  [symbol/string] - account_id or currency of account to get data from
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
  id: .ref.getAccID[x];
  res: .py.list .ord.CLI.get_account_holds[id];
  holds: $[count res; "ZGFSG"$/:res; :(::)];
  holds};
0ng
flls:.ord.getFills[`BTCUSD;"8bf53216-2726-4cf5-920d-1599336454b0";3214116]
.sim.exmp flls
///
// Get a list of recent fills.
//
// example:
// q) .ord.getFills[`BTCUSD;`;`]
// q) .ord.getFills[`BTCUSD;"a1b2c3d4";3214116]
//
// parameters:
// sym    [symbol/string] - ccy pair/product, fetch trades with this product_id
// ordID  [symbol/string] - order_id, fetch trades with this order_id
// b4     [long] - trade_id, fetch all trades with greater trade_id (newer fills)
//
// returns:
// flls [table] - Contain
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
// wraps: get_account_holds
//  api - https://docs.pro.coinbase.com/#fills
//  lib - https://github.com/michaelsimonelli/qoinbase-py/blob/master/cbpro/authenticated_client.py#L578
.ord.getFills:{[sym;ordID;b4]
  arg: `product_id`order_id`before!(.ut.defn[;.py.none] each (sym; ordID; b4)); 

  if[not .py.none~arg[`product_id];
    arg: @[arg; `product_id; .ref.getPID]];

  res: .ord.CLI.get_fills[pykwargs arg];
  tmp: .py.list res;
  tmp: "*jSGSG*FFFSbF"$/:tmp;
  flls: update .ut.iso2Q'[created_at], raze/[liquidity] from tmp;

  flls};

.ord.getOrders:{[sym;status]
  arg: `product_id`status!(.ut.defn[;.py.none] each (sym; status));

  if[not .py.none~arg[`product_id];
    arg: @[arg; `product_id; .ref.getPID]];

  res: .ord.CLI.get_orders[pykwargs arg];
  tmp: .py.list res; if[not count tmp; :(::)];
  ord: (distinct raze(key@/:tmp))#.ref.orderTemp$/:tmp;
  
  if[`created_at in cols ord;
    ord: update .ut.iso2Q'[created_at] from ord];
  if[`done_at in cols ord;
    ord: update .ut.iso2Q'[done_at] from ord];

  ord};

.ord.getOrder:{[ordID]
  res: .ord.CLI.get_order[ordID];
  ord: (key res)#.ref.orderTemp$res;
  if[`created_at in key ord;
    ord: @[ord;`created_at;.ut.iso2Q]];
  if[`done_at in key ord;
    ord: @[ord;`done_at;.ut.iso2Q]];
  ord};

.ord.placeMarketOrder:{[sym;side;size]
  pid: .ref.getPID[sym];
  res: .ord.CLI.place_market_order[pid; side; size];
  ord: (key res)#.ref.orderTemp$res;
  if[`created_at in key ord;
    ord: @[ord;`created_at;.ut.iso2Q]];
  ord};

.ord.placeLimitOrder:{[sym;side;price;size]
  pid: .ref.getPID[sym];
  res: .ord.CLI.place_limit_order[pid; side; price; size];
  ord: (key res)#.ref.orderTemp$res;
  if[`created_at in key ord;
    ord: @[ord;`created_at;.ut.iso2Q]];
  ord};
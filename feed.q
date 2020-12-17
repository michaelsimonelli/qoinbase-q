// **********************************************
// feed.q
// websocket subscription and data feed
// **********************************************

\l ws.q

.data.md:([sym:`symbol$()]bp:`float$();ap:`float$();tp:`float$();vwap:`float$());

.data.quote:([] time:`timestamp$();sym:`symbol$();bpx:`float$();apx:`float$());

.data.trade:([] time:`timestamp$();sym:`symbol$();price:`float$();bid:`float$();ask:`float$();side:`$();size:`float$();id:`long$());

.feed.URLS:`live`test!("wss://ws-feed.pro.coinbase.com"; "wss://ws-feed-public.sandbox.pro.coinbase.com");

.feed.url:"wss://ws-feed-public.sandbox.pro.coinbase.com";
.feed.url:"wss://ws-feed.pro.coinbase.com";
.feed.products:`$("BTC-USD";"ETH-USD";"ETH-BTC");
.feed.channels:(`level2`ticker);

.feed.cfg.DTH: 5;
.feed.cfg.BKD: 5*.feed.cfg.DTH;
.feed.cfg.STD: 100*.feed.cfg.DTH;

.book.bids.:(::);
.book.asks.:(::);

.book.state.bids.:(::);
.book.state.asks.:(::);

.feed.book.cut:{x sublist y}[.feed.cfg.BKD];
.feed.state.cut:{x sublist y}[.feed.cfg.STD];

.book.full:{[sym] (,'/).book[`bids`asks;sym]};

.book.view:{[sym;depth] depth sublist .book.full[sym]};

.book.vwap:{[sym;bs;depth] 
  side:(`buy`sell!(`aqty`asks;`bqty`bids))[bs];
  book:.[.book.full;(sym;([]lvl:til depth);side)];
  vwap:.[wavg;] flip book;
  vwap};

.feed.state.rebal:{[side;sym]
  .[`.book.state; (side; sym); .feed.state.expired];
  .[`.book.state; (side; sym); .feed.state.sort[side]];
  rebal: .feed.rec.book[side; sym];
  rebal};

.feed.state.expired:{(where x=0)_x};

.feed.state.sort:{[side;data]
  sortF: $[`bids=side; desc; asc];
  sortD: .feed.state.cut (sortF[key data]#data);
  sortD};

.feed.state.snap:{[snap;side]
  sym: snap`product_id;
  state: .feed.state.cut snap side;
  .book.state[side; sym]: state;
  };

.feed.book.get:{[side;sym]
  head: side,$[side=`bids; `bqty; `aqty];
  state: (key; value)@\:.book.state[side; sym];
  book: flip head!.feed.book.cut each state;
  book};

.feed.rec.book:{[side;sym]
  old: .book[side; sym];
  new: .feed.book.get[side; sym];
  if[upd: not new ~ old;
    .book[side; sym]: new];
  upd};

.feed.rec.state:{[sym;chg]
  price: chg 1; size: chg 2;
  side: $[not chg[0] in `buy`sell; 'badSide; `buy=chg[0]; `bids; `asks];
  .book.state[side; sym; price]: size;
  rebal: .feed.state.rebal[side; sym];
  rebal};

.feed.rec.md:{[sym;time;updQuote];
  bp: max key .book.state.bids[sym];
  ap: min key .book.state.asks[sym];
  mdEvt: (bp; ap); mdSym: `bp`ap;
  if[any updMD: where not mdEvt=.data.md[sym; mdSym];
    .[`.data.md; (sym; mdSym[updMD]); :; mdEvt[updMD]];
    if[updQuote;`.data.quote upsert (time; sym; bp; ap)];
  ];
  };

.feed.heartbeat: ([product_id:`symbol$()] lastUpdate:`timestamp$(); latent:`timespan$());

.feed.evt.subscriptions:{
  subs: ungroup "SS"$/:x`channels;
  .feed.subs,: @[subs; `product_ids; .Q.id'];
  .feed.subs: distinct .feed.subs;
  };

.feed.evt.heartbeat:{
  x: "SjSjZ"$x;
  x: @/[x; `product_id`time; (.Q.id; "p"$)];
  hb: select lastUpdate: first time by product_id from enlist x;

  `.feed.heartbeat upsert hb;
  update latent: .z.p-lastUpdate from `.feed.heartbeat;

  if[count stale: exec product_id from .feed.heartbeat where latent > 00:00:05;
    if[inactive: .ut.isNull value .ws.W neg .feed.h; .feed.init[]];
    resub: 0!select name by product_ids from select asc distinct product_ids
            by name from select from .feed.subs where product_ids in stale;
    .feed.sub[.feed.h;;] ./: resub`product_ids`name;
  ]
  };

.feed.evt.ticker:{
  if[not any `trade_id`time in key x;:(::)];
  if[.ut.isNull x`time;:(::)];
  x:"SFFFSZjF"$`product_id`price`best_bid`best_ask`side`time`trade_id`last_size#x;
  x:`sym`price`bid`ask`side`time`id`size!value x;
  x:@[x;`sym;.Q.id];
  x:@[x;`time;"p"$];
  if[.ut.isNull x`id; x[`id]:0N];
  .[`.data.md;(x`sym;`tp);:;x`price];
  `.data.trade upsert x;
  };

.feed.evt.snapshot:{
  x: "SSFF"$x;
  x: @[x; `product_id; .Q.id];
  x: @[x; `bids`asks; {(!/) flip x}];
  .feed.state.snap[x] each `bids`asks;
  .feed.state.rebal[;x`product_id] each `bids`asks;
  .feed.rec.md[x`product_id;`;0b];
  };

.feed.evt.l2update:{
  x:"SS*Z"$x;
  sym: .Q.id x`product_id;
  time: "p"$x`time;
  change: "SFF"$/:x`changes;
  stateChange: .feed.rec.state[sym] each change;
  if[any stateChange;
    .feed.rec.md[sym; time; 0b]];
  }

.feed.upd:{
  e:.j.k x;
  t:`$e`type;
  if[t in key .feed.evt;
    .feed.evt[t]e];
  };

.feed.sub:{[h;p;c]
  p: string .ut.enlist .ref.getPID'[p];
  c: string .ut.enlist c union `heartbeat;
  s: .j.j (`type`product_ids`channels)!("subscribe"; p; c);
  h[s];
  };

.feed.usub:{[h;p;c]
  p: string .ut.enlist .ref.getPID'[p];
  c: string .ut.enlist c;
  s:.j.j (`type`product_ids`channels)!("unsubscribe"; p; c);
  h[s];
  };  

.feed.init:{[]
  env: .cli.MKT.getEnv[];
  url: .feed.URLS env;
  .feed.h: .ws.open[url; `.feed.upd];
  };
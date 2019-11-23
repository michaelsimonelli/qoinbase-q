
///
// Cast data returned by the client
// 
.scm.cast:{[x]
  x: $[(.ut.isGList x) and (.ut.isDict first x); .scm.ldjn;]x;
  b: (::; flip).ut.isTable x; x: b x; 
  f: .scm.fnCast@'(.scm.map key x);
  r: f@'x;
  b r};

.scm.default:{y;.scm.fn.string x};
.scm.fnCast:{[fn;x] @[fn; x; .scm.default x]};
.scm.guid:{all x like "*-????-????-????-*"};
.scm.long:{all {all x in"+-0123456789"}'[x]};
.scm.ldjn:{r:x where (type each x)=99h;((distinct raze(key@/:r))#/:r)};
.scm.cfrm:{$[not .scm.rcvt x;{{?[.ut.isNull'[x];(x#:)#("",:);]x}.ut.toStr x};]x};
.scm.rcvt:{t:{$[.ut.isGList x;.scm.rcvt;type]x}'[x];first $[1<count t;{(0h,x)({min x=/:y}.(0 1) cut x)};]t};
.scm.tryCast:{if[any 99h=type each y; :y]; y:.scm.cfrm[y]; if[x~.ut.typ.map type y 0; :y]; $[.scm.canCast[x]y; x$;]y};
.scm.canCast:{[x;y] .[{nw:x$"";if[not x in"BGXCS";nw:(min 0#;max 0#;::)@\:nw];$[not any nw in x$11#y;$[11<count y;not any nw in x$y;1b];@[{x$y;1b}[x];y;0b]]};(x;y);0b]};


.scm.fn.string:{s:.ut.toStr'[x];?[s like "::";(count x)#enlist "";s]};
.scm.fn.qtime:{.scm.fn[$[(abs type x) in 5 6 7 8 9h; `epoch; `iso]]x};
.scm.fn.epoch:{if[.ut.isList x; .z.s'[x]]; `datetime$(x % 86400) - 10957f};
.scm.fn.id:{.scm.fn[$[any i:(.scm.guid;.scm.long)@\:x;first `guid`long where i;`symbol]]x};
.scm.fn.iso:{if[(not .ut.isStr x) and .ut.isList x; :.z.s'[x]]; if[not .ut.isNull t:"Z"$x;:t]; "Z"$-1_x};
.scm.fn,:(raze {enlist[x`sym]!enlist[.scm.tryCast[x`chr]]} each select sym,chr from .ut.typ.ref where int < 0);

.scm.ref: .ut.table (
  (`field                   , `cast);
  (`id                      , `id);
  (`ref                     , `id);
  (`user_id                 , `id);
  (`order_id                , `id);
  (`profile_id              , `id);
  (`trade_id                , `long);
  (`bid                     , `float);
  (`ask                     , `float);
  (`fee                     , `float);
  (`size                    , `float);
  (`hold                    , `float);
  (`funds                   , `float);
  (`price                   , `float);
  (`amount                  , `float);
  (`volume                  , `float);
  (`balance                 , `float);
  (`min_size                , `float);
  (`available               , `float);
  (`fill_fees               , `float);
  (`stop_price              , `float);
  (`usd_volume              , `float);
  (`filled_size             , `float);
  (`hold_balance            , `float);
  (`max_precision           , `float);
  (`executed_value          , `float);
  (`base_min_size           , `float);
  (`base_max_size           , `float);
  (`base_increment          , `float);
  (`specified_funds         , `float);
  (`quote_increment         , `float);
  (`min_market_funds        , `float);
  (`max_market_funds        , `float);
  (`min_withdrawal_amount   , `float);
  (`stp                     , `symbol);
  (`name                    , `symbol);
  (`side                    , `symbol);
  (`type                    , `symbol);
  (`stop                    , `symbol);
  (`status                  , `symbol);
  (`currency                , `symbol);
  (`liquidity               , `symbol);
  (`product_id              , `symbol);
  (`group_types             , `symbol);
  (`done_reason             , `symbol);
  (`display_name            , `symbol);
  (`hold_currency           , `symbol);
  (`time_in_force           , `symbol);
  (`base_currency           , `symbol);
  (`quote_currency          , `symbol);
  (`convertible_to          , `symbol);
  (`push_payment_methods    , `symbol);
  (`time                    , `xtime);
  (`done_at                 , `iso);
  (`created_at              , `iso);
  (`expire_time             , `iso);
  (`active                  , `boolean);
  (`primary                 , `boolean);
  (`settled                 , `boolean);
  (`post_only               , `boolean);
  (`accessible              , `boolean);
  (`limit_only              , `boolean);
  (`cancel_only             , `boolean);
  (`margin_enabled          , `boolean);
  (`available_on_consumer   , `boolean);
  (`message                 , `string);
  (`status_message          , `string);
  (`sort_order              , `int);
  (`network_confirmations   , `int);
  (`processing_time_seconds , `int));

.scm.map: exec field!.scm.fn[cast] from .scm.ref;

  
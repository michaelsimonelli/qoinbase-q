\l ut.q
\l scm.q
\l extend.q

.py.import[`cbpro];
.py.reflection.emulate[`cbpro];

// Register parameters
.ut.params.registerOptional[`cbpro; `CBPRO_APP_DIR; system"cd"; "Client start up path"];
.ut.params.registerOptional[`cbpro; `CBPRO_API_KEY; `;"Coinbase Pro API access key"];
.ut.params.registerOptional[`cbpro; `CBPRO_API_SECRET; `;"Coinbase Pro API secret key"];
.ut.params.registerOptional[`cbpro; `CBPRO_API_PASSPHRASE; `;"Coinbase Pro API user passphrase"];

// Main Client
.CLI.main:();

// Market Data Client
.CLI.mkt:();

// Order Management Client
.CLI.ord:();

.cbpro.cli.public:{[env]
  apiurl: .api.endpoint[env];  

  client: .cbpro.priv.addFuncs .cbpro.PublicClient[apiurl];

  client};

.cbpro.cli.auth: .ut.xfunc {[x]
  .ut.assert[(count x) in 1 4;"Invalid number of arguments, accepts valence of 1 OR 4"];

  .sim.x:x;
  env: .ut.xposi[x; 0; `env];
  apiurl: .api.endpoint[env];
  auth: .cbpro.priv.access . x[1 2 3];

  if[any .ut.isNull each auth;
    '"Invalid authentication", $[(count x)=1; ", check env vars: `CBPRO_API_KEY`CBPRO_API_SIGN`CBPRO_API_PASSPHRASE";""]];

  client: .cbpro.priv.addFuncs .cbpro.AuthenticatedClient[(auth[`apikey`secret`passphrase],enlist apiurl)];

  client};

///
// API CONTEXT
/////////////////////////////

.api.inst:();

.api.loaded:();

.api.URLS:`live`test!("https://api.pro.coinbase.com"; "https://api-public.sandbox.pro.coinbase.com");

.api.endpoint:{[x] .ut.assert[not .ut.isNull u: .api.URLS[x]; "env must be one of (",(.Q.s1 key .api.URLS),")"]; u};

.api.load:{[l]
  dir: getenv `CBPRO_APP_DIR;
  .ut.lg"Loading ",(string l)," api library";
  if[@[{system x;1b};"l ",("/" sv (dir; l$:)),".q";0b];
    .api.loaded,:l];
  };

.api.init: .ut.xfunc {[x]
  typ: .ut.xposi[x; 0; `typ];
  lib: .ut.xposi[x; 1; `lib];
  env: .ut.xposi[x; 2; `env];

  if[(lib=`ord) and not `mkt in .api.inst; .api.init[typ;`mkt;env]];
  
  .ut.lg"Initialing ",(string lib)," api client";

  if[not lib in .api.loaded; .api.load lib];

  cli: $[.ut.isNull .CLI.main; .cbpro.cli[typ] . (2 _ x); .CLI.main];

  .CLI[lib]: cli;

  .ref.cache[lib][];

  .api.inst,: lib;

  res: ` sv `,lib;

  res};

///
// PRIVATE CONTEXT
/////////////////////////////
.cbpro.priv.access:{[api_key;secret;passphrase]
  a: .ut.default[api_key;     `$getenv `CBPRO_API_KEY];
  s: .ut.default[secret;      `$getenv `CBPRO_API_SECRET];
  p: .ut.default[passphrase;  `$getenv `CBPRO_API_PASSPHRASE];
  r: `apikey`secret`passphrase!(a;s;p);
  r};.

.cbpro.priv.isAuth:{[x]
  r: @[x`get_accounts; ::; `];
  a: not $[.ut.isTable r; 
            0b; 
            .ut.isNull r; 
              1b; 
              .ut.isDict r; 
                (`message in key r); 
                0b];
  a};

.cbpro.priv.getEnv:{[x;y] .api.URLS ? x[`url][]};

.cbpro.priv.setEnv:{[x;y] if[y in key .api.URLS; x[`url][.api.URLS y]]; x[`getEnv][]};

.cbpro.priv.addFuncs:{[c]
  c[`isAuth]: .cbpro.priv.isAuth c;
  c[`getEnv]: .cbpro.priv.getEnv c;
  c[`setEnv]: .cbpro.priv.setEnv c;
  c};


/$[.ut.isTable r;             0b;             .ut.isNull r;               1b;               .ut.isDict r;                 (`message in key r);                 0b];
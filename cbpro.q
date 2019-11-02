\l ut.q
\l extend.q

.py.import[`cbpro];
.py.reflection.emulate[`cbpro];

// Register parameters
.ut.params.registerOptional[`cbpro; `CBPRO_APP_DIR; system"cd"; "Client start up path"];
.ut.params.registerOptional[`cbpro; `CBPRO_API_KEY; `;"Coinbase Pro API access key"];
.ut.params.registerOptional[`cbpro; `CBPRO_API_SIGN; `;"Coinbase Pro API secret key"];
.ut.params.registerOptional[`cbpro; `CBPRO_API_PASSPHRASE; `;"Coinbase Pro API user passphrase"];

// API env endpoints
.api.URLS:`live`test!("https://api.pro.coinbase.com"; "https://api-public.sandbox.pro.coinbase.com");

// Main Client
.cli.MAIN:();

// Market Data Client
.cli.MKT:();

// Order Management Client
.cli.ORD:();

.cbpro.cli.public:{[env]
  apiurl: .env.endpoint[env];  

  client: .cbpro.priv.addFuncs .cbpro.PublicClient[apiurl];

  client};

.cbpro.cli.auth: .ut.xfunc {[x]
  .ut.assert[(count x) in 1 4;"Invalid number of arguments, accepts valence of 1 OR 4"];

  env: .ut.xposi[x; 0; `env];
  apiurl: .env.endpoint[env];
  auth: .cbpro.priv.auth . x[1 2 3];

  if[any .ut.isNull each auth;
    '"Invalid authentication", $[(count x)=1; ", check env vars: `CBPRO_API_KEY`CBPRO_API_SIGN`CBPRO_API_PASSPHRASE";""]];

  client: .cbpro.priv.addFuncs .cbpro.AuthenticatedClient[(auth[`apikey`secret`phrase],enlist apiurl)];

  client};

///
// API CONTEXT
/////////////////////////////

.api.loaded:();
.api.inst:();

.api.load:{[l]
  dir: getenv `CBPRO_APP_DIR;
  if[@[{system x;1b};"l ",("/" sv (dir; l$:)),".q";0b];
    .api.loaded,:l];
  };

.api.init:{[env]
  .cli.MAIN: .cbpro.cli.auth[env];
  .cli.MKT: .cli.ORD: .cli.MAIN;

  if[not `mkt in .api.loaded; .api.load `mkt];
  if[not `ord in .api.loaded; .api.load `ord];

  .ref.cache.mkt[];
  .ref.cache.ord[];

  .api.inst: .api.inst union `mkt`ord;

  `mkt`ord};

.api.init0: .ut.xfunc {[x]
  typ: .ut.xposi[x; 0; `typ];
  lib: .ut.xposi[x; 1; `lib];
  env: .ut.xposi[x; 2; `env];

  if[(lib=`ord) and not `mkt in .api.inst; '"Dependency: Market api must be initialized"];
  
  if[not lib in .api.loaded;
    .api.load lib];

  cli: $[.ut.isNull .cli.MAIN; .cbpro.cli[typ] . (2 _ x); .cli.MAIN];

  .CLI[lib]: cli;

  .ref.cache[lib][];

  .api.inst,: lib;

  res: ` sv `,lib;

  res};

///
// PRIVATE CONTEXT
/////////////////////////////

.env.endpoint:{[x] .ut.assert[not .ut.isNull u: .api.URLS[x]; "env must be one of (",(.Q.s1 key .api.URLS),")"]; u};

.cbpro.priv.access:{[api_key;secret;passphrase]
  a: .ut.default[api_key;     `$getenv `CBPRO_API_KEY];
  s: .ut.default[secret;      `$getenv `CBPRO_API_SIGN];
  p: .ut.default[passphrase;  `$getenv `CBPRO_API_PASSPHRASE];
  r: `apikey`sign`pass!(a;s;p);
  r};

acc:.cbpro.priv.access . aa
acc`key
.cbpro.priv.isAuth:{[x]
  r: @[x`get_accounts; ::; `];
  a: not $[.ut.isTable r; 
            0b; 
            .ut.isNull r; 
              1b; 
              .ut.isDict r; 
                (`message in key r) and ("Invalid API Key"~r`message); 
                0b];
  a};

.cbpro.priv.getEnv:{[x;y] .api.URLS ? x[`url][]};

.cbpro.priv.setEnv:{[x;y] if[y in key .api.URLS; x[`url][.api.URLS y]]; x[`getEnv][]};

.cbpro.priv.addFuncs:{[c]
  c[`isAuth]: .cbpro.priv.isAuth c;
  c[`getEnv]: .cbpro.priv.getEnv c;
  c[`setEnv]: .cbpro.priv.setEnv c;
  c};

pc.isAuth
pc`get_accounts
pc:.cbpro.cli.public[`live]
ac:.cbpro.cli.auth[`live]
@[pc`get_accounts;::]
r:pc[`get_accounts][]
r:alt.get_accounts[]
r:ac.get_accounts[]
pc
if[.ut.isDict r;
if[
not 
.ut.isTable r
not 
not $[.ut.isTable r; 0b; .ut.isNull r; 1b; .ut.isDict r; (`message in key r) and ("Invalid API Key"~r`message); 0b]
$[.ut.isTable r; 0b; $[.ut.isDict r;(`message in key r) and ("Invalid API Key"~r`message);0b]]



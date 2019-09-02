\l ut.q
\l extend.q

.py.import[`cbpro];
.py.reflection.emulate[`cbpro];

.cbpro.urls:`live`test!("https://api.pro.coinbase.com"; "https://api-public.sandbox.pro.coinbase.com");

///
// CLIENT CONTEXT
/////////////////////////////

// Global Market Data Client
.CLI.mkt:();

// Global Order Management Client
.CLI.ord:();

.cbpro.cli.public:{[env]
  apiurl: .cbpro.priv.apiurl[env];  

  client: .cbpro.priv.addFuncs .cbpro.PublicClient[apiurl];

  client};

.cbpro.cli.auth: .ut.xfunc {[x]
  .ut.assert[(count x) in 1 4;"Invalid number of arguments, accepts valence of 1 OR 4"];

  env: .ut.xposi[x; 0; `env];
  apiurl: .cbpro.priv.apiurl[env];
  auth: .cbpro.priv.auth @ x[ 1 2 3];

  if[any .ut.isNull each auth;
    '"Invalid authentication", $[(count x)=1; ", check env vars: `CB_ACCESS_KEY`CB_ACCESS_SIGN`CB_ACCESS_PASSPHRASE";""]];

  client: .cbpro.priv.addFuncs .cbpro.AuthenticatedClient[(auth[`apikey`secret`phrase],enlist apiurl)];

  client};

///
// API CONTEXT
/////////////////////////////

.cbpro.api.loaded:();
.cbpro.api.inst:();

.cbpro.api.load:{[l]
  dir: getenv `CB_DIR;
  if[@[{system x;1b};"l ",("/" sv (dir; l$:)),".q";0b];
    .cbpro.api.loaded,:l];
  };

.cbpro.api.init: .ut.xfunc {[x]
  typ: .ut.xposi[x; 0; `typ];
  lib: .ut.xposi[x; 1; `lib];
  env: .ut.xposi[x; 2; `env];

  if[(lib=`ord) and not `mkt in .cbpro.api.inst; '"Dependency: Market api must be initialized"];
  
  if[not lib in .cbpro.api.loaded;
    .cbpro.api.load lib];

  cli: .cbpro.cli[typ] . (2 _ x);

  .CLI[lib]: cli;

  .ref.cache[lib][];

  .cbpro.api.inst,: lib;

  res: ` sv ``api,lib;

  res};

///
// PRIVATE CONTEXT
/////////////////////////////

.cbpro.priv.apiurl:{[x] .ut.assert[not .ut.isNull u: .cbpro.urls[x]; "env must be one of (",(.Q.s1 key .cbpro.urls),")"]; u};

.cbpro.priv.auth:{[x]
  a: .ut.default[x 0; `$getenv `CB_ACCESS_KEY];
  s: .ut.default[x 1; `$getenv `CB_ACCESS_SIGN];
  p: .ut.default[x 2; `$getenv `CB_ACCESS_PASSPHRASE];
  r: `apikey`secret`phrase!(a;s;p);
  r};

.cbpro.priv.isAuth:{[x] @[.ut.isTable; @[x`get_accounts;::;`]]};

.cbpro.priv.getEnv:{[x;y] .cbpro.urls ? x[`url][]};

.cbpro.priv.setEnv:{[x;y] if[y in key .cbpro.urls; x[`url][.cbpro.urls y]]; x[`getEnv][]};

.cbpro.priv.addFuncs:{[c]
  c[`isAuth]: .cbpro.priv.isAuth c;
  c[`getEnv]: .cbpro.priv.getEnv c;
  c[`setEnv]: .cbpro.priv.setEnv c;
  c};

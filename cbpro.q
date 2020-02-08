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
.cli.MAIN:();

// Market Data Client
.cli.MKT:();

// Order Management Client
.cli.ORD:();

.cli.public:{[env]
  apiurl: .api.endpoint[env];  

  client: .cli.priv.addFuncs .cli.PublicClient[apiurl];

  client};

.cli.auth: .ut.xfunc {[x]
  .ut.assert[(count x) in 1 4;"Invalid number of arguments, accepts valence of 1 OR 4"];

  env: .ut.xposi[x; 0; `env];
  apiurl: .api.endpoint[env];
  auth: .cli.priv.access . x[1 2 3];

  if[any .ut.isNull each auth;
    '"Invalid authentication", $[(count x)=1; ", check env vars: `CBPRO_API_KEY`CBPRO_API_SIGN`CBPRO_API_PASSPHRASE";""]];

  client: .cli.priv.addFuncs .cbpro.AuthenticatedClient . ((value auth),enlist apiurl);

  client};

///
// API CONTEXT
/////////////////////////////

.api.loaded:();

.api.URLS:`live`test!("https://api.pro.coinbase.com"; "https://api-public.sandbox.pro.coinbase.com");

.api.endpoint:{[x] .ut.assert[not .ut.isNull u: .api.URLS[x]; "env must be one of (",(.Q.s1 key .api.URLS),")"]; u};

.api.load:{[l]
  dir: getenv `CBPRO_APP_DIR;
  .ut.lg"Loading ",(string l)," api library";
  if[@[{system x;1b};"l ",("/" sv (dir; l$:)),".q";0b];
    .api.loaded,:l];
  };

.api.init:{[typ;env]
  .ut.assert[typ in `public`auth; "Invalid 'type' param - must be `public or `auth"];
  .ut.assert[env in `test`live; "Invalid 'env' param - must be `test or `live"];
  
  lib: $[typ ~ `public; `mkt; `ord];

  if[.ut.isNull .cli.MAIN; .cli.MAIN: .cli[typ][env]];

  if[lib ~ `ord;
    if[not `mkt in .api.loaded;
      .api.load `mkt;
      .cli.MKT: .cli.MAIN;
    ];
  ];

  if[not lib in .api.loaded; .api.load lib];

  .cli[upper lib]: .cli.MAIN;

  .ref.cache[lib][];

  .api.inst,: lib;

  `apiInit};

///
// PRIVATE CONTEXT
/////////////////////////////
.cli.priv.access:{[api_key;secret;passphrase]
  a: .ut.default[api_key;     `$getenv `CBPRO_API_KEY];
  s: .ut.default[secret;      `$getenv `CBPRO_API_SECRET];
  p: .ut.default[passphrase;  `$getenv `CBPRO_API_PASSPHRASE];
  r: `apikey`secret`passphrase!(a;s;p);
  r};.

.cli.priv.isAuth:{[x]
  r: @[x`get_accounts; ::; `];
  a: not $[.ut.isTable r; 
            0b; 
            .ut.isNull r; 
              1b; 
              .ut.isDict r; 
                (`message in key r); 
                0b];
  a};

.cli.priv.getEnv:{[x;y] .api.URLS ? x[`url][]};

.cli.priv.setEnv:{[x;y] if[y in key .api.URLS; x[`url][.api.URLS y]]; x[`getEnv][]};

.cli.priv.addFuncs:{[c]
  c[`isAuth]: .cli.priv.isAuth c;
  c[`getEnv]: .cli.priv.getEnv c;
  c[`setEnv]: .cli.priv.setEnv c;
  c};


/$[.ut.isTable r;             0b;             .ut.isNull r;               1b;               .ut.isDict r;                 (`message in key r);                 0b];
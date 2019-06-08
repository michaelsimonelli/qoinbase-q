
.cli.loaded:();

.cli.load:{[l]
  dir: getenv `CB_DIR;
  if[@[{system x;1b};"l ",("/" sv (dir; l$:)),".q";0b];
    .cli.loaded,:l];
  };

.cli.init: .ut.xfunc {[x]
  typ: .ut.xposi[x; 0; `typ];
  lib: .ut.xposi[x; 1; `lib];
  env: .ut.xposi[x; 2; `env];
  
  if[not lib in .cli.loaded;
    .cli.load lib];

  cli: .cbpro.cli[typ] . (2 _ x);

  res: (value `$".",string[lib])[`init; cli];

  res};

.cli.init[`public;`mkt;`live];
.cli.init[`auth;`ord;`test];


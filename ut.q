.ut.isSym:{ -11h = type x };

.ut.isStr:{ 10h = type x };

.ut.isGuid:{ -2h = type x };

.ut.isAtom:{ (0h > type x) and (-20h < type x) };

.ut.isList:{ (0h <= type x) and (20h > type x) };

.ut.isGList:{ 0h = type x };

.ut.isTable:{ .Q.qt x };

.ut.isDict:{ $[99h = type x;not .ut.isTable x; 0b] };

.ut.isNull:{ $[.ut.isAtom[x] or .ut.isList[x] or x ~ (::); $[.ut.isGList[x]; all .ut.isNull each x; all null x]; .ut.isTable[x] or .ut.isDict[x];$[count x;0b;1b];0b ] };

.ut.toStr:{if[.ut.isStr x; :x]; string x};

.ut.enlist:{ $[not .ut.isList x;enlist x; x] };

.ut.raze:{ $[.ut.isList x; [tmp:raze x; $[1 = count tmp; first tmp; tmp] ]; x] };

.ut.repeat:{ .ut.enlist[x]!count[x]#y };

.ut.cast:{ x $ { $[(::)~x; string;] x} each y };

.ut.default:{ $[.ut.isNull x; y; x] };

.ut.xfunc:{ (')[x; enlist] };

.ut.xposi:{ .ut.assert[not .ut.isNull x y; "positional argument (",(y$:),") '",(z$:),"' required"]; x y};

.ut.assert:{ [x;y] if[not x;'"Assert failed: ",y] };

.ut.q2iso:{[qtime]
  if[not (typ: type qtime) in (-12h;-15h);'"datetime or timestamp expected"];
  if[-15h = typ;qtime:"p"$qtime];
  iso:-6 _ .h.iso8601 "j"$qtime;
  iso};

.ut.iso2Q:{ if[not .ut.isNull t:"Z"$x;:t]; "Z"$ $[24<>ct:count x;ssr[x;"Z";((23;22;20)!("0Z";"00Z";".000Z"))ct]; x] };

.ut.epo2Q:{`datetime$(x % 86400) - 10957f};

///
// Parameter Registration API
// ______________________________________________

.ut.params.registerRequired:{[component; name; descr]
  param:enlist each `component`name`val`required`descr!(component;name;`;1b;`$descr);
  .ut.params.registered:.ut.params.registered,2!flip param;
  .ut.params.priv.updateFromEnv[component; name];
  };

.ut.params.registerOptional:{[component; name; default; descr]
  param:enlist each `component`name`val`required`descr!(component;name;default;0b;`$descr);
  .ut.params.registered:.ut.params.registered,2!flip param;
  .ut.params.priv.updateFromEnv[component; name];
  };

.ut.params.get:{[component_]
  // Assert component exist
  if[exec not component_ in component from .ut.params.registered; 'InvalidComponent];
  // Assert non-null required
  missing:exec name from .ut.params.registered where component = component_, required, .ut.isNull'[val];
  // Signal if missing
  if[0<>count missing;
    '`$"ERROR: Missing required params (", string[component_],"): ",", " sv string missing];
  // Return name->value dict
  params:exec name!.ut.raze'[val] from .ut.params.registered where component=component_;
  params};

.ut.params.set:{[names; values]
  names:.ut.enlist[names];
  values:.ut.enlist[values];
  // Match names to values (can be on to many)
  setting:names!$[(1 = count names) and 1 < count values; enlist values; values];
  // Select params with name, set new values, and get types
  params:select component, name, val:setting name, ty:type each val from .ut.params.registered where name in names;
  // For each param row
  { // Attempt to cast
    x[`val]:.[$;(abs x`ty; x`val);{x`val}[x]];
    // Conform if list
    if[.ut.isList x`ty; x[`val]:.ut.enlist x`val];
    // Update
    .ut.params.priv.update[x`component; x`name; x`val];
  } each params;
  };

.ut.params.registered:([component:`symbol$(); name:`symbol$()] val:(); required:`boolean$(); descr:`symbol$());

.ut.params.priv.update:{[component_; name_; val_]
  // Get the old param row as a dict
  param:exec from `.ut.params.registered where component = component_, name = name_;
  // Remove the old param (facilitates atom -> list type change)
  delete from `.ut.params.registered where component = component_, name = name_;
  // Set the new param value
  param[`val]:val_;
  // Convert the param dict into a table
  param:2!enlist param;
  // Join the new 'param' table with the existing table
  .ut.params.registered,:param;
  };

.ut.params.priv.updateFromEnv:{[component; name]
  param:getenv name;

  if[.ut.isNull param; :0];

  if[1<count param; param:string .ut.raze `$"|" vs param];

  typ:.ut.type .ut.params.registered[component,name; `val];
  param:typ[`chr]$param;

  .ut.params.priv.update[component; name; param];
  };


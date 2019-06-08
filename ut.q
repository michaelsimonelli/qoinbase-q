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




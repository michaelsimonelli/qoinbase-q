///
// extendPy
//
// Extends embedPy
// - provides dynamic module import
// - maps python module->class->functions to a native q context/function library
// ____________________________________________________________________________

\l p.q
\l reflect.p

.py.ut.isTabl:{ .Q.qt x };
.py.ut.eachKV:{ key [x]y'x};
.py.ut.isGLst:{ 0h = type x };
.py.ut.logger:{-1 (string .z.z)," ", x};
.py.ut.isAtom:{ (0h > type x) and (-20h < type x) };
.py.ut.isList:{ (0h <= type x) and (20h > type x) };
.py.ut.enlist:{ $[not .py.ut.isList x;enlist x; x] };
.py.ut.isDict:{ $[99h = type x;not .py.ut.isTabl x; 0b] };
.py.ut.strSym:{ if[any {(type x) in ((5h$til 20)_10),98 99h}@\:x; :.z.s'[x]]; $[10h = abs type x; `$x; x] };
.py.ut.isNull:{ $[.py.ut.isAtom[x] or .py.ut.isList[x] or x ~ (::); $[.py.ut.isGLst[x]; all .py.ut.isNull each x; all null x]; .py.ut.isTabl[x] or .py.ut.isDict[x];$[count x;0b;1b];0b ] };
.py.ut.fapply:{(('[;])over reverse y)x};
.py.ut.ns: enlist[`]!enlist[::];

.py.meta:.py.ut.ns;

.py.modules: ()!();

.py.moduleInfo: .p.get[`module_info;<];

.py.classInfo: .p.get[`class_info;<];

// Import a python module
//
// parameters:
// module [symbol] - module name
// as     [symbol] - alias to avoid clashes
.py.import:{[module] 
  if[module in key .py.modules;
    .py.ut.logger"Module already imported"; :(::)];
  if[@[{.py.modules[x]:.p.import x; 1b}; module; .py.importError[module]];
      .py.ut.logger"Imported python module '",string[module],"'"];
  };

.py.importError:{[module; error]
  -1"Python module '",string[module],"' failed with: ", "(",error,")";
  0b};

///
// Reflect a python module into kdb context
// Creates a context in the .pq name space
// Context root is a dictionary of class_name->projection
// The projection is a callable init function returning a function library
// Library is a callable dictionary of function_name->embedPy function
//
// parameters:
// module [symbol] - module to reflect (must be imported)
.py.reflect:{[module]
  pyModule: .py.modules[module];
  modInfo: .py.moduleInfo[pyModule];
  clsInfo: modInfo[`classes];
  project: .py.rt.project[pyModule; clsInfo];
  (` sv `,module ) set project;
  .py.meta[module]:modInfo;
  1b};

///
// Maps python module functions to callable q functions
// Mapped functions are stored in respective module context in .pq namespace
//
// parameters:
// module [symbol]    - module to map from (must be imported)
// module [list(sym)] - list of functions to map
.py.map:{[module; functions; as]
  pyModule:.py.modules[module];
  qRef:$[.py.ut.isNull as;module;as];

  if[not (.py.ut.isDict .py[qRef]) and (first .py[qRef]~(::));
    .py[qRef]:.py.ut.ns];

  mapping:functions!pyModule[;<]@'hsym functions;
  .py[qRef],:mapping;
  };

///
// Creates a pseudo generator callable in q
//
// parameters:
// func     [symbol]  - type of generator, accepts: list or next
//  list - returns the entire iterator as one object
//  next - returns the next object in the iterator
//  (type dependent on iterator, next is callable until iterator exhausted)
// iterator [foreign] - embedPy iterator
// nul      [null]    - null param to prevent function from executing
.py.generate:{[func;generator;nul]
  res:.py.builtins[func;generator];
  res};

///
// Create some useful embedPy tools
.py.ini:`$"__init__";

.py.none:.p.eval"None"; 

.py.isNone:{x~.py.none};

.py.import[`builtins];

.py.map[`builtins;`list`next`vars`str;`];

.py.qcall:{.p.qcallable[x hsym y]}';

.py.feta:{[m;c] .py.meta[m; `classes; c; `attributes; `functions]};

.py.peta:{[m;c;f] .py.meta[m; `classes; c; `attributes; `functions; f; `parameters]};

///////////////////////////////////////
// PRIVATE CONTEXT                   //
///////////////////////////////////////

.py.rt.project:{[imp; cls]
  p: .py.ut.eachKV[cls;{
      obj: x hsym y;
      atr: z`attributes;
      cxt: .py.rt.context[obj; atr];
      cxt}[imp]];
  p};

.py.rt.context:{[obj; atr; arg]
  data: atr`data;
  prop: atr`properties;
  func: atr`functions;

  init: func[.py.ini];
  params: init[`parameters];
  required: params[::;`required];

  if[(arg~(::)) and (any required);
    '"Missing required parameters: ",", " sv string where required];

  arg: .py.rt.args[arg];
  ins: $[1<count arg;.;@][obj;arg];

  func _: .py.ini;
  vars: .py.builtins.vars[ins];
  docs: .py.ut.ns;

  if[count data; docs[`data]: data];
  if[count prop; docs[`prop]: prop];
  if[count func; docs[`func]: func];
  if[count vars; docs[`vars]: vars];

  cxD: .py.rt.data.cxt[ins; data];
  cxP: .py.rt.prop.cxt[ins; prop];
  cxF: .py.rt.func.cxt[ins; func];
  cxV: .py.rt.vars.cxt[ins; vars];
  cxt: .py.ut.ns,cxD,cxP,cxF,cxV;
  
  cxt[`docs_]: docs;

  cxt};

.py.rt.args:{[args]
  if[args~(::);:args];
  
  args: .py.ut.strSym[args];

  if[.py.ut.isDict args;
    if[10h = type key args;
      args:({`$x} each key args)!value args];
    ]; 

  args: $[.py.ut.isDict args; pykwargs args; 
          (.py.ut.isGLst args) and (.py.ut.isDict last args);
            (pyarglist -1 _ args; pykwargs last args); 
              pyarglist args];
  args};

.py.rt.data.cxt:{[pin; info]
  dkey: key info;
  dval: pin@'hsym dkey;
  cxt: dkey!dval;
  cxt};

.py.rt.prop.cxt:{[pin; info]
  cxt: .py.ut.eachKV[info; 
    {[pin; name; prop]
      hpy: hsym name;
        gsm: (enlist `get)!(enlist pin[hpy;]);
          if[prop`setter; gsm[`set]:pin[:hpy;]];
            prj:.py.rt.prop.prj[gsm];
              prj} pin];
  cxt};

.py.rt.prop.prj:{[qco; arg]
  acc: $[arg~(::); [arg:`; `get]; `set];

  if[.py.ut.isNull func:qco[acc];
    'string[typ]," accessor not available"];

  res:func[arg];

  res}

.py.rt.func.cxt:{[pin; info]
  fns: key info;
  cxt: fns!{[pin;fn]
        prj:.py.qcall[pin;] fn;
          prj}[pin] each fns;
  cxt};

.py.rt.func.prj:{[qco; arg]
  arg: .py.ut.enlist $[.py.ut.isNull arg; (::); arg];
  res: qco . arg;
  res};

.py.rt.vars.cxt:{[pin; info]
  vkey: key info;
  vpns: hsym vkey;
  vmap: {[pin; vpn] 
          gtf: pin[vpn;];
            stf: pin[:;vpn;];
              gsm: `get`set!(gtf;stf);
                prj:.py.rt.prop.prj[gsm];
                  prj}[pin;] each vpns;
  cxt: (!/)($[1>=count vkey; .py.ut.enlist each;](vkey;vmap));
  cxt};

.pyp.idx: 0;

.pyp.ref:([]module:`symbol$();class:`symbol$();ins:`symbol$();cxt:`symbol$());

.pyp.point:{[r;v]
  i: string "i"$.pyp.idx;
  n: `$".pyp.",string[r],i;
  n set v;
  n};

.pyp.makeRef:{[pin;pix]
  module: `$ first "." vs pin[`:__module__;`];
  class: `$ pin[`:__class__.__name__;`];
  .pyp.ref,:(module; class; pin; pix);
  .pyp.idx+:1;

  last .pyp.ref};

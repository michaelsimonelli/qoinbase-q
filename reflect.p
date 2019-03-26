import io
import pyment
from enum import IntEnum
from inspect import *
from collections import namedtuple, OrderedDict


# Python q reflection functions.
#
# Utility module for py.q embedPy framework.
# Provides metadata and type information for imported python modules


# Python q reflection functions.
#
# Utility module for py.q embedPy framework.
# Provides metadata and type information for imported python modules

def module_info(module):
    # Returns member info for an imported python module.
    
    # Multilevel nested dictionary:
    #   - module
    #   -- classes
    #   --- attributes
    #   ----- properties
    
    mem = Member(module)
    classes = {}
    for cls in mem.get_members(isclass):
        attributes = OrderedDict()
        attributes['data'] = {x.name: x.cxt() for x in cls.get_data()}
        attributes['properties'] = {x.name: x.cxt() for x in cls.get_properties()}
        attributes['functions'] = {x.name: x.cxt() for x in cls.get_functions()}
        attr_cxt = dict(attributes=attributes, doc=cls.doc)
        classes.update({cls.name: attr_cxt})
    
    mod_info = dict(classes=classes)
    return mod_info


def class_info(obj):
    if isclass(obj):
        obj = Member(obj)
    if not isclass(obj.typ):
        return
    attributes = OrderedDict()
    attributes['data'] = {x.name: x.cxt() for x in obj.get_data()}
    attributes['properties'] = {x.name: x.cxt() for x in obj.get_properties()}
    attributes['functions'] = {x.name: x.cxt() for x in obj.get_functions()}
    cls_attr = dict(attributes=attributes, doc=obj.doc)
    return cls_attr


def member_info(obj):
    mem = Member(obj)
    return mem.qmap()


def get_attrs(ins):
    inst_vars = {}
    for key, val in vars(ins):
        if key.startswith('_'):
            continue
        ptyp = _obj_name(type(val))
        inst_cxt = dict(pval=val, ptyp=ptyp)
        inst_vars.update({key: inst_cxt})
    return inst_vars


def get_classes(obj):
    return [m for m in getmembers(obj, isclass) if not m[0].startswith('_')]


def get_functions(obj):
    func = [Member(m[1], m[0]) for m in getmembers(obj, isroutine) if not m[0].startswith('_')]
    func = [dict(name=f.name, doc=f.doc, obj=f.obj, ) for f in func]
    return func


#############################
# Internal Functions - not to be used in kdb
#############################


Element = namedtuple('Element', 'name desc ptyp')


class AttrType(IntEnum):
    INIT = 0,
    CLASS_VAR = 1,
    PROPERTY = 2,
    INSTANCE_METHOD = 3,
    CLASS_METHOD = 4,
    STATIC_METHOD = 5


class Member:
    def __init__(self, obj, name=None):
        self.obj = obj
        self.name = name
        if not self.name:
            self.name = _obj_name(obj)
        self.doc = _obj_doc(self.obj)
        self.typ = type(self.obj)
        self.mod = _obj_mod(self.obj)
        try:
            self.cls = _obj_cls(self.obj)
        except AttributeError:
            self.cls = None
    
    def qmap(self):
        mem = self.name
        obj = self.obj
        typ = _obj_out(self.typ)
        cls = _obj_out(self.cls)
        mod = _obj_out(self.mod)
        qd = {'q': dict(mem=mem, typ=typ[0], cls=cls[0], mdl=mod[0])}
        pd = {'p': dict(mem=obj, typ=typ[1], cls=cls[1], mdl=mod[1])}
        qd.update(pd)
        return qd
    
    def get_members(self, predicate):
        return [Member(m[1], m[0]) for m in getmembers(self.obj, predicate)]
    
    def get_data(self):
        data_info = [DataInfo(a) for a in classify_class_attrs(self.obj)
                     if _is_pub(a.name) and a.kind is 'data']
        return data_info
    
    def get_functions(self):
        method_info = [FuncInfo(a) for a in classify_class_attrs(self.obj)
                       if _is_pub(a.name) and 'method' in a.kind]
        return method_info
    
    def get_properties(self):
        property_info = [PropertyInfo(a) for a in classify_class_attrs(self.obj)
                         if _is_pub(a.name) and a.kind is 'property']
        return property_info


class AttrInfo(Member):
    _kind_map = {
        'static method': AttrType.STATIC_METHOD,
        'class method':  AttrType.CLASS_METHOD,
        'property':      AttrType.PROPERTY,
        'method':        AttrType.INSTANCE_METHOD,
        'data':          AttrType.CLASS_VAR
    }
    
    def __init__(self, attr: Attribute):
        super().__init__(attr.object, attr.name)
        self.def_class = attr.defining_class
        self.attr_kind = attr.kind
        
        if attr.name is '__init__':
            _attr_type = AttrType.INIT
        else:
            _attr_type = self._kind_map[attr.kind]
            if attr.name.startswith('_'):
                self.exposed = False
        
        self.attr_type = _attr_type
        self.properties = {}
    
    def cxt(self):
        kind = self.attr_type.name.lower()
        meta = {'kind': kind, **self.properties, 'doc': self.doc}
        return meta


class DataInfo(AttrInfo):
    def __init__(self, attr: Attribute):
        super().__init__(attr)
        self.pval = self.obj
        self.ptyp = _obj_name(type(self.pval))
        self.properties = dict(pval=self.pval, ptyp=self.ptyp)


class PropertyInfo(AttrInfo):
    def __init__(self, attr: Attribute):
        super().__init__(attr)
        prop = self.obj
        accessors = dict(getter='fget', setter='fset')
        self.properties = {k: not not getattr(prop, v) for k, v in accessors.items()}


class FuncInfo(AttrInfo):
    def __init__(self, attr: Attribute):
        super().__init__(attr)
        self.signature = None
        self.document = None
        self.parameters = {}
        self.returns = {}
        self.properties = dict(parameters={}, returns={})
        if self.func:
            self.profile()
    
    @property
    def func(self):
        if callable(self.obj):
            return self.obj
        if hasattr(self.obj, '__func__'):
            return self.obj.__func__
    
    def profile(self):
        try:
            self.signature = signature(self.func)
        except ValueError:
            return
        
        self.document = _doc_meta(self.func)
        
        _parameters = {}
        param_meta = self.document.get('params', None)
        for param in self.signature.parameters.values():
            if param.name is 'self':
                continue
            
            param_info = ParamInfo(param)
            if param_meta and param.name in param_meta:
                data = param_meta[param.name]
                param_info.doc = data.desc.splitlines()
                param_info.ptyp = data.ptyp
            
            param_cxt = param_info.cxt()
            _parameters.update(param_cxt)
        
        _returns = {}
        return_meta = self.document.get('return', None)
        if return_meta:
            data = [*return_meta.values()][0]
            doc = data.desc.splitlines()
            ptyp = data.ptyp
            _returns = dict(doc=doc, ptyp=ptyp)
        
        self.parameters = _parameters
        self.returns = _returns
        self.properties = dict(parameters=self.parameters, returns=self.returns)


class ParamInfo(Member):
    def __init__(self, param: Parameter):
        super().__init__(param, param.name)
        self.ptyp = ''
        self.param_kind = param.kind
        self.has_default = param.default is not Parameter.empty
        self.default = param.default if self.has_default else None
        self._variadic = self.param_kind in [2, 4]
        self.required = not self._variadic and not self.has_default
    
    def cxt(self):
        kind = self.param_kind.name.lower()
        ptyp = self.ptyp.replace('Optional', '').strip('[]')
        cxt = dict(kind=kind, ptyp=ptyp,
                   default=self.default, has_default=self.has_default,
                   required=self.required, doc=self.doc)
        return {self.name: cxt}


def _obj_doc(obj):
    _doc = getdoc(obj)
    return _doc.splitlines() if isinstance(_doc, str) else ''


def _obj_mod(obj):
    mod = getmodule(obj)
    if ismodule(mod):
        pkg = mod.__package__
        base = sys.modules.get(pkg, None)
        return base


def _obj_name(obj):
    for i in range(0, 4):
        if i == 0:
            pass
        elif i == 1:
            if hasattr(obj, '__func__'):
                obj = obj.__func__
        elif i == 2:
            if isinstance(obj, property):
                obj = obj.fget
        elif i == 3:
            obj = type(obj)
        if hasattr(obj, '__name__'):
            return obj.__name__


def _obj_cls(obj):
    if isbuiltin(obj):
        return obj.__class__
    if _is_prop(obj):
        cls = _obj_qual(obj.fget)
        if cls:
            return cls
    if _is_bound(obj):
        cls = _obj_qual(obj.__func__)
        if cls:
            return cls
    if ismethod(obj):
        for cls in getmro(obj.__self__.__class__):
            if cls.__dict__.get(obj.__name__) is obj:
                return cls
        obj = obj.__func__  # fallback to __qualname__ parsing
    cls = _obj_qual(obj)
    if cls:
        return cls
    return getattr(obj, '__objclass__', None)  # handle special descriptor objects


def _obj_qual(obj):
    if isfunction(obj):
        cls = getattr(getmodule(obj),
                      obj.__qualname__.split('.<locals>', 1)[0].rsplit('.', 1)[0])
        if isinstance(cls, type):
            return cls


def _obj_out(obj):
    name = _obj_name(obj)
    return name, obj


def _is_bound(obj):
    _self = getattr(obj, '__self__', None)
    return _self is not None


def _is_prop(obj):
    return isinstance(obj, property)


def _is_pub(name):
    return not name.startswith('_') or name is '__init__'


def _doc_meta(obj):
    meta = {'params': {}, 'return': {}}
    try:
        src = getsource(obj)
    except (TypeError, OSError):
        return meta
    
    stream = io.StringIO(src)
    
    sys.stdin = stream
    pyc = pyment.PyComment('-')
    pyc.docs_init_to_class()
    sys.stdin = sys.__stdin__
    
    doc_list = pyc.docs_list[0]['docs']
    doc_index = doc_list.docs['in']
    
    for mk in meta.keys():
        item = doc_index[mk]
        if item:
            data = {i[0]: Element(*i) for i in item}
            meta[mk] = data
    
    return meta


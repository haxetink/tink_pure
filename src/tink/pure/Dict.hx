package tink.pure;

#if macro
  import haxe.macro.Context.*;
  using haxe.macro.Tools;
  using tink.MacroApi;
#end

// @:jsonParse(tink.pure.Dict.ofMap)
@:jsonParse(map -> @:privateAccess new tink.pure.Dict(map))
@:jsonStringify(map -> @:privateAccess tink.pure.Dict.toJson(map))
@:forward(exists, keys, iterator, keyValueIterator)
abstract Dict<K, V>(Map<K, V>) {

  inline function new(data)
    this = data;

  @:to public function copy()
    return this.copy();

  extern public inline function count(?f:V->Bool)
    return Lambda.count((cast this:haxe.Constraints.IMap<K, V>), f);

  extern public inline function exists(f:V->Bool)
    return Lambda.exists((cast this:haxe.Constraints.IMap<K, V>), f);

  extern public inline function fold<R>(f:(v:V, result:R)->R, init:R)
    return Lambda.fold((cast this:haxe.Constraints.IMap<K, V>), f, init);

  static extern public inline function empty<K, V>():Dict<K, V> {
    return new Dict<K, V>([]);
  }

  @:arrayAccess
  public inline function get(key:K):Null<V>
    return this.get(key);

  overload extern public inline function with(k:K, v:V):Dict<K, V> {
    var ret = this.copy();

    ret.set(k, v);

    return new Dict(ret);
  }

  static function toJson<K, V>(d:Dict<K, V>):Map<K, V>
    return cast d;

  overload extern public inline function with<Values:KeyValueIterable<K, V>>(values:Values):Dict<K, V> {
    var ret = this.copy();

    for (k => v in values)
      ret.set(k, v);

    return new Dict(ret);
  }

  overload extern public inline function without(k:K):Dict<K, V> {
    var ret = this.copy();

    ret.remove(k);

    return new Dict(ret);
  }

  overload extern public inline function without<Keys:Iterable<K>>(keys:Keys):Dict<K, V> {
    var ret = this.copy();
    for (k in keys)
      ret.remove(k);
    return new Dict(ret);
  }

  extern public inline function filter(condition:(entry:{ var key(default, null):K; var value(default, null):V; })->Bool):Dict<K, V>
    return new Dict([for (p in this.keyValueIterator()) if (condition(p)) p.key => p.value]);

  #if macro @:from #end
  static public inline function ofMap<K, V>(m:Map<K, V>)
    return new Dict(m.copy());

  @:to public inline function toString():String
    return this.toString();

  @:from macro static function ofAny(e) {
    var stored, typed = typeExpr(e);

    return switch typed.expr {
      case TArrayDecl([]) | TNew(_.get() => {pack: ['haxe', 'ds', '_Map'], name: 'Map_Impl_'}, [TMono(_), TMono(_)], []):
        macro @:pos(e.pos) @:privateAccess new tink.pure.Dict(new Map());
      case _:
        try {
          var expectedk, expectedv;
          switch getExpectedType() {
            case t = TAbstract(_, [k, v]):
              expectedk = k.toComplex();
              expectedv = v.toComplex();
            case v:
              throw 'unreachable';
          }

          switch typeExpr(macro ($e:Map<$expectedk, $expectedv>)) {
            case outer = {expr: TParenthesis({expr: TCast(inner, _)})}:
              typed = inner;
              stored = storeTypedExpr(outer);
            case _:
              throw 'unreachable';
          }
        } catch(ex:Dynamic) {
          typed = typeExpr(e);
          stored = storeTypedExpr(typed);
        }

        switch typed.expr {
          case TBlock([ // this is how the compiler transforms array comprehension syntax into typed exprs
              {expr: TVar({id: initId, name: name, t: TAbstract(_.get() => {pack: ['haxe', 'ds'], name: 'Map'}, _)}, {expr: TNew(_)})},
              {expr: TBlock(exprs)},
              {expr: TLocal({id: retId})},
          ]) if(initId == retId && name.charCodeAt(0) == '`'.code):
            macro @:pos(e.pos) @:privateAccess new tink.pure.Dict($stored);
          default:
            macro @:pos(e.pos) tink.pure.Dict.ofMap($stored);
        }
    }
  }
}
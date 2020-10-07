package tink.pure;

#if macro
  import haxe.macro.Context.*;
  using haxe.macro.Tools;
#end

@:forward(length, indexOf, contains, iterator, keyValueIterator)
@:pure
@:jsonParse(a -> @:privateAccess new tink.pure.Vector(a))
@:jsonStringify(vec -> @:privateAccess vec.unwrap())
abstract Vector<T>(Array<T>) to Vectorlike<T> {

  inline function new(a)
    this = a;

  inline function unwrap()
    return this;

  @:arrayAccess
  public inline function get(index)
    return this[index];

  public inline function map<R>(f:T->R)
    return new Vector(this.map(f));

  public inline function filter(f:T->Bool)
    return new Vector(this.filter(f));

  @:op(a & b)
  public inline function concat(that:Vectorlike<T>)
    return new Vector(this.concat(cast that));

  @:op(a & b)
  static inline function lconcat<T>(a:Vectorlike<T>, b:Vector<T>)
    return new Vector(a.concat(b.unwrap()));

  #if macro @:from #end
  static public inline function fromArray<T>(a:Array<T>)
    return new Vector(a.copy());

  #if macro @:from #end
  static public inline function fromMutable<T>(v:haxe.ds.Vector<T>)
    return new Vector(v.toArray());

  #if macro @:from #end
  static public inline function fromIterable<T>(v:Iterable<T>)
    return new Vector([for (x in v) x]);

  @:from macro static function ofAny(e) {
    var t = typeExpr(e);
    e = storeTypedExpr(t);
    return switch t.expr {
      case TArrayDecl(_):
        macro @:pos(e.pos) @:privateAccess new tink.pure.Vector(${e});
      default:
        switch follow(t.t) {
          case TInst(_.get() => { pack: [], name: 'Array' }, _):
            macro @:pos(e.pos) tink.pure.Vector.fromArray(${e});
          case TAbstract(_.get() => { pack: ['haxe', 'ds'], name: 'Vector' }, _):
            macro @:pos(e.pos) tink.pure.Vector.fromMutable(${e});
          default:
            macro @:pos(e.pos) tink.pure.Vector.fromIterable(${e});
        }
    }
  }
}

@:forward
private abstract Vectorlike<T>(Array<T>) from Array<T> {
  @:from static function ofSingle<T>(v:T):Vectorlike<T>
    return [v];
}
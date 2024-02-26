package tink.pure;

#if macro
  import haxe.macro.Context.*;
  using haxe.macro.Tools;
  using tink.MacroApi;
#end

@:forward(length, indexOf, contains, iterator, keyValueIterator, join)
@:pure
@:jsonParse(a -> @:privateAccess new tink.pure.Vector(a))
@:jsonStringify(vec -> @:privateAccess vec.unwrap())
abstract Vector<T>(Array<T>) to Vectorlike<T> to Iterable<T> {

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

  public inline function sorted(compare:(T, T)->Int) {
    var a = this.copy();
    a.sort(compare);
    return new Vector(a);
  }

  public inline function slice(pos, end)
    return new Vector(this.slice(pos, end));

  public inline function count(f)
    return Lambda.count(this, f);

  public inline function exists(f)
    return Lambda.exists(this, f);

  public inline function find(f)
    return Lambda.find(this, f);

  public inline function findIndex(f)
    return Lambda.findIndex(this, f);

  public inline function fold<R>(f:(v:T, result:R)->R, init:R)
    return Lambda.fold(this, f, init);

  public inline function with(index:Int, value:T):Vector<T> {
    final arr = this.copy();
    arr[index] = value;
    return new Vector(arr);
  }

  @:op(a & b)
  public inline function concat(that:Vectorlike<T>)
    return new Vector(this.concat(cast that));

  @:op(a & b)
  static inline function lconcat<T>(a:Vectorlike<T>, b:Vector<T>)
    return new Vector(a.concat(b.unwrap()));

  static public inline function empty<T>():Vector<T> {
    return new Vector<T>([]);
  }

  @:from static function fromVector<T, R:T>(v:Vector<R>):Vector<T>
    return cast v;

  #if macro @:from #end
  static public inline function fromArray<T, R:T>(a:Array<R>)
    return new Vector<T>(cast a.copy());

  #if macro @:from #end
  static public inline function fromMutable<T, R:T>(v:haxe.ds.Vector<R>)
    return new Vector<T>(cast v.toArray());

  #if macro @:from #end
  static public inline function fromIterable<T, R:T>(v:Iterable<R>)
    return new Vector<T>([for (x in v) x]);

  @:to public inline function toArray()
    return this.copy();

  @:from macro static function ofAny(e) {
    var stored, typed;
    try {
      var expected = switch getExpectedType() {
        case TAbstract(_, [t]): t.toComplex();
        case v: throw 'unreachable';
      }
      switch typeExpr(macro ($e:Array<$expected>)) {
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

    return switch typed.expr {
      case TArrayDecl(_) | TNew(_.get() => {pack: [], name: 'Array'}, [_], []):
        macro @:pos(e.pos) @:privateAccess new tink.pure.Vector($stored);
      case TBlock([ // this is how the compiler transforms array comprehension syntax into typed exprs
          {expr: TVar({id: initId, name: name}, {expr: TArrayDecl([])})},
          {expr: TBlock(exprs)},
          {expr: TLocal({id: retId})},
      ]) if(initId == retId && name.charCodeAt(0) == '`'.code):
        macro @:pos(e.pos) @:privateAccess new tink.pure.Vector(${stored});
      default:
        switch follow(typed.t) {
          case TInst(_.get() => { pack: [], name: 'Array' }, _):
            macro @:pos(e.pos) tink.pure.Vector.fromArray($stored);
          case TAbstract(_.get() => { pack: ['haxe', 'ds'], name: 'Vector' }, _):
            macro @:pos(e.pos) tink.pure.Vector.fromMutable($stored);
          default:
            macro @:pos(e.pos) tink.pure.Vector.fromIterable($stored);
        }
    }
  }
}

@:forward
private abstract Vectorlike<T>(Array<T>) from Array<T> {
  @:from static function ofSingle<T>(v:T):Vectorlike<T>
    return [v];
}

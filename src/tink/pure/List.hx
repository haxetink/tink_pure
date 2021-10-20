package tink.pure;

using tink.CoreApi;

@:enum abstract FilterResult(Int) {
  var ExcludeAndStop = -3;
  var Exclude = 0;
  var Include = 1;
  var IncludeAndStop = 3;

  public inline function include()
    return this > 0;

  public inline function stop()
    return this & 3 == 3;

  @:from static inline function fromBool(b:Bool)
    return
      if (b) Include
      else Exclude;
}

@:jsonParse(tink.pure.List.fromArray)
@:jsonStringify(l -> l.toArray())
@:using(tink.pure.List.NamedListIterator)
@:using(tink.pure.List.PairListIterator)
abstract List<T>(Node<T>) from Node<T> {
  public var length(get, never):Int;
    inline function get_length()
      return this == null ? 0 : this.length;

  public function first(?predicate:T->Bool):haxe.ds.Option<T> {
    for (x in iterator())
      if (predicate == null || predicate(x)) return Some(x);
    return None;
  }

  public function last(?predicate:T->Bool):haxe.ds.Option<T> {
    return if(this == null) {
      None;
    } else if(predicate == null) {
      function _last(v:Node<T>):haxe.ds.Option<T>
        return switch v.tails {
          case []: Some(v.value);
          case tails: _last(tails[tails.length -1]);
        }
      _last(node());
    } else {
      var found = false;
      var ret = null;
      for (x in iterator()) if (predicate(x)) {
        found = true;
        ret = x;
      }
      found ? Some(ret) : None;
    }
  }

  public function get(index:Int):haxe.ds.Option<T> {
    if(index < 0) return None;
    var iter = iterator();
    var v = null;
    while(index-- >= 0) {
      if(!iter.hasNext()) return None;
      v = iter.next();
    }
    return Some(v);
  }

  public function new()
    this = null;

  inline function node()
    return this;

  public function concat(that:List<T>):List<T>
    return
      if (this == null)
        that;
      else if (that == null)
        this;
      else
        new Node(
          this.length + that.length,
          this.value,
          this.tails.concat([that.node()])
        );

  public function sort(compare:T->T->Int) {
    var arr = toArray();
    arr.sort(compare);
    return fromArray(arr);
  }

  public function append(value:T):List<T>
    return
      if (this == null)
        new Node(1, value);
      else
        new Node(this.length + 1, this.value, this.tails.concat([new Node(1, value)]));

  public function prepend(value:T):List<T>
    return
      if (this == null)
        new Node(1, value);
      else
        new Node(this.length + 1, value, [this]);

  public function replace(select:ReplaceSelector<T>, generate:ReplaceGenerator<T>):List<T>
    return fromArray([for(v in iterator()) if(select(v)) generate(v) else v]);

  public inline function exists(predicate:T->Bool) {
    var ret = false;
    for (x in iterator())
      if (predicate(x)) {
        ret = true;
        break;
      }
    return ret;
  }

  public inline function count(predicate:T->Bool) {
    var ret = 0;
    for (x in iterator())
      if (predicate(x)) ret++;
    return ret;
  }

  public inline function iterator():NodeIterator<T>
    return new NodeIterator(this);

  @:to public inline function toIterable():Iterable<T>
    return {
      iterator: iterator,
    }

  public function filter(f:T->FilterResult):List<T>
    return
      if (this == null) null;
      else this.filter(f);

  public function map<A>(f:T->A):List<A>
    return fromArray([for(i in iterator()) f(i)]);

  public function select<A>(f:T->haxe.ds.Option<A>):List<A> {
    var arr = [];
    for(i in iterator()) switch f(i) {
      case Some(v): arr.push(v);
      case None: // skip
    }
    return fromArray(arr);
  }

  public function fold<A>(f:T->A->A, first:A):A {
    for(x in iterator())
      first = f(x, first);
    return first;
  }

  static public inline function single<A>(v:A):List<A>
    return new Node(1, v);

  public function toArray():Array<T>
    return [for(v in iterator()) v];

  @:from static public function fromArray<A>(i:Array<A>):List<A> {
    var ret = null,
        len = 0,
        pos = i.length;

    while (pos --> 0)
      ret = new Node(++len, i[pos], if (ret == null) cast Node.EMPTY else [ret]);

    return ret;
  }
}

@:generic private class Node<T> {
  public var length(default, null):Int;
  public var value(default, null):T;
  public var tails(default, null):Array<Node<T>>;//consider using haxe.ds.Vector

  public function new(length, value, ?tails) {
    this.value = value;
    this.length = length;
    this.tails = tails == null ? cast EMPTY : tails;
  }

  public function filter(f:T->FilterResult):Node<T> {
    var iter = new NodeIterator(this);
    var ret = [];
    while (iter.hasNext()) {
      var value = iter.next();
      var res = f(value);
      if (res.include())
        ret.push(value);
      if (res.stop())
        break;
    }
    return @:privateAccess List.fromArray(ret).node();
  }
  static public var EMPTY = [];
}

class NodeIterator<T> {
  var list:Array<Node<T>>;

  public function new(node) {
    this.list = [];
    if (node != null)
      list.push(node);
  }

  public inline function hasNext()
    return list.length > 0;

  public function next():T
    return
      switch list.pop() {
        case null: null;
        case next:
          for (i in -next.tails.length...0)
            list.push(next.tails[ -i - 1]);
          next.value;
      }
}

@:callable
private abstract ReplaceSelector<T>(T->Bool) from T->Bool to T->Bool {
  @:from
  public static function const<T>(v:T):ReplaceSelector<T>
    return function(i) return i == v;
}

@:callable
private abstract ReplaceGenerator<T>(T->T) from T->T to T->T {
  @:from
  public static function const<T>(v:T):ReplaceGenerator<T>
    return function(_) return v;
}

class NamedListIterator<K, V> {
  final it:NodeIterator<NamedWith<K, V>>;
  public function new(it)
    this.it = it;

  public inline function hasNext()
    return it.hasNext();

  public inline function next() {
    var ret = it.next();
    return { key: ret.name, value: ret.value };
  }
  static public function keyValueIterator<K, V>(l:List<NamedWith<K, V>>):KeyValueIterator<K, V>
    return new NamedListIterator(l.iterator());
}

class PairListIterator<K, V> {
  final it:NodeIterator<Pair<K, V>>;
  public function new(it)
    this.it = it;

  public inline function hasNext()
    return it.hasNext();

  public inline function next() {
    var ret = it.next();
    return { key: ret.a, value: ret.b };
  }
  static public function keyValueIterator<K, V>(l:List<Pair<K, V>>):KeyValueIterator<K, V>
    return new PairListIterator(l.iterator());
}
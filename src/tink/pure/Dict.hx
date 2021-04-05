package tink.pure;

import haxe.Rest;

@:forward(exists, keys, iterator, keyValueIterator, copy)
abstract Dict<K, V>(Map<K, V>) {

  inline function new(data)
    this = data;

  @:arrayAccess
  public inline function get(key:K):Null<V>
    return this.get(key);

  overload extern public inline function with(k:K, v:V):Dict<K, V> {
    var ret = this.copy();

    ret.set(k, v);

    return new Dict(ret);
  }

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

  @:from static public inline function ofMap<K, V>(m:Map<K, V>) 
    return new Dict(m.copy());

  @:to public inline function toString():String
    return this.toString();
}
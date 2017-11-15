package tink.pure;

import tink.Slice as MSlice;

@:forward(length, iterator)
abstract Slice<T>(MSlice<T>) to MSlice<T> {

  inline function new(v:MSlice<T>) 
    this = v;

  @:arrayAccess inline function get(index:Int):T
    return this[index];

  static function make<T>(v:MSlice<T>)
    return new Slice(if (v.isShared || v.getOverhead() > 1.0) v.compact() else v);

  @:from static inline function ofArray<T>(a:Array<T>)
    return make(a);

  @:from static inline function ofVector<T>(v:haxe.ds.Vector<T>)
    return make(v);

}
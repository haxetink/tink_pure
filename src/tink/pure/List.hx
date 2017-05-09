package tink.pure;

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

abstract List<T>(Node<T>) from Node<T> {
  public var length(get, never):Int;
    inline function get_length()
      return this == null ? 0 : this.length;

  public inline function first():haxe.ds.Option<T>
    return 
      if (this == null) None;
      else Some(this.value);

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
  
  public function prepend(value:T):List<T> 
    return 
      if (this == null)
        new Node(1, value);
      else
        new Node(this.length + 1, value, [this]);
  
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

  @:to function toIterable():Iterable<T>
    return {
      iterator: iterator,
    }
    
  public function filter(f:T->FilterResult):List<T>
    return 
      if (this == null) null;
      else this.filter(f);
      
  @:from static public function fromArray<A>(i:Array<A>):List<A> {
    var ret = null,
        len = 0,
        pos = i.length;

    while (pos --> 0)
      ret = new Node(++len, i[pos], if (ret == null) cast Node.EMPTY else [ret]);
      
    return ret;
  }
  
  #if tink_json
  
  @:to function toRepresentation():tink.json.Representation<Array<T>> 
    return new tink.json.Representation([for(n in iterator()) n]);
    
  @:from static function ofRepresentation<T>(rep:tink.json.Representation<Array<T>>)
    return List.fromArray(rep.get());
    
  #end

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

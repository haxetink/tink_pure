package tink.pure;

using tink.CoreApi;

abstract Sequence<T>(SequenceObject<T>) from SequenceObject<T> {
	@:from
	public static inline function ofSingle<T>(v:T):Sequence<T>
		return new SingleSequence(v);
		
	@:from
	public static inline function ofArray<T>(v:Array<T>):Sequence<T>
		return ofIterable(v.copy());
		
	// @:from -- well somehow @:from causes recursive casts here
	// don't expose this, we can't guarantee purity on arbitary iterables
	static inline function ofIterable<T>(v:Iterable<T>):Sequence<T>
		return new IterableSequence(v);
		
	@:to
	public function iterator():Iterator<T>
		return this == null ? EmptyIterator.inst : this.iterator();
		
	@:to
	public function toIterable():Iterable<T>
		return this == null ? EmptySequence.inst : this;
		
	@:to
	public inline function toArray():Array<T>
		return Lambda.array(toIterable());
		
	public inline function map<A>(f:T->A):Sequence<A>
		return new CachedSequence(new MapSequence(this, f));
	
	public inline function filter(f:Filter<T>):Sequence<T>
		return new CachedSequence(new FilterSequence(this, f));
	
	public inline function concat(other:Sequence<T>):Sequence<T>
		return new NestedSequence(ofArray([this, other]));
	
	public inline function empty():Bool
		return Lambda.empty(toIterable());
	
	public inline function exists(f:Filter<T>):Bool
		return Lambda.exists(toIterable(), f);
	
	@:impl // https://github.com/HaxeFoundation/haxe/issues/6157
	public static inline function _flatten<T>(seq:SequenceObject<Sequence<T>>):Sequence<T>
		return flatten(seq);
	
	public static inline function flatten<T>(seq:Sequence<Sequence<T>>):Sequence<T>
		return new NestedSequence(seq);
	
	public inline function find(f:Filter<T>):T
		return Lambda.find(toIterable(), f);
	
	public inline function count(?f:Filter<T>):Int
		return Lambda.count(toIterable(), f);
	
	public function join(delim:String):String {
		var buf = new StringBuf();
		var first = true;
		for(v in iterator()) {
			if(!first) buf.add(',');
			else first = false;
			buf.add(v);
		}
		return buf.toString();
	}
}

@:callable
private abstract Filter<T>(T->Bool) from T->Bool to T->Bool {
	@:from
	public static inline function ofConst<T>(v:T):Filter<T>
		return function(i:T) return i == v;
}

interface SequenceObject<T> {
	function iterator():Iterator<T>;
}

class IterableSequence<T> implements SequenceObject<T> {
	var iterable:Iterable<T>;
	public function new(iterable)
		this.iterable = iterable;
	public inline function iterator():Iterator<T>
		return iterable.iterator();
}

class NestedSequence<T> implements SequenceObject<T> {
	var seq:Sequence<Sequence<T>>;
	
	public function new(seq)
		this.seq = seq;
		
	public function iterator():Iterator<T>
		return new NestedIterator(seq.iterator());
}

class NestedIterator<T> {
	var iter:Iterator<Sequence<T>>;
	var current:Iterator<T>;
	
	public function new(iter) {
		this.iter = iter;
		advance();
	}
		
	public function hasNext()
		return current == null ? false : current.hasNext();
	
	public function next() {
		if(current == null) return null;
		var v = current.next();
		if(!current.hasNext()) advance();
		return v;
	}
	
	function advance()
		current = iter.hasNext() ? iter.next().iterator() : null;
		
}

class SingleSequence<T> implements SequenceObject<T> {
	var item:T;
	
	public inline function new(item)
		this.item = item;
		
	public inline function iterator():Iterator<T>
		return new SingleIterator(item);
}

class SingleIterator<T> {
	var item:T;
	var consumed = false;
	
	public function new(item)
		this.item = item;
		
	public inline function hasNext()
		return !consumed;
		
	public inline function next()
		return
			if(consumed) 
				null;
			else {
				consumed = true;
				item;
			}
}

class CachedSequence<T> implements SequenceObject<T> {
	var cache:Array<T>;
	var iter:Iterator<T>;
	var finished = false;
	
	public function new(seq:Sequence<T>) {
		iter = seq.iterator(); // make sure we ever iterate the underlying sequence once
		cache = [];
	}
	
	public function iterator():Iterator<T> {
		if(finished) return cache.iterator();
		
		var i = 0;
		return {
			hasNext: function() {
				if(i < cache.length) return true;
				return switch iter.hasNext() {
					case false: finished = true; false;
					case true: true;
				}
			},
			next: function() {
				i++;
				return if(i >= cache.length) {
					var next = iter.next();
					cache.push(next);
					next;
				} else {
					cache[i];
				}
			}
		}
	}
}

private class EmptySequence<T> implements SequenceObject<T> {
	public static var inst(default, null) = new EmptySequence();
	public function new() {}
	public inline function iterator():Iterator<T> return EmptyIterator.inst;
}

private class EmptyIterator<T> {
	public static var inst(default, null):EmptyIterator<Dynamic> = new EmptyIterator();
	public function new() {}
	public inline function hasNext() return false;
	public inline function next():T return null;
}

class FilterSequence<T> implements SequenceObject<T> {
	var seq:Sequence<T>;
	var f:T->Bool;
	
	public function new(seq, f) {
		this.seq = seq;
		this.f = f;
	}
	
	public inline function iterator():Iterator<T>
		return new FilterIterator(seq.iterator(), f);
}

class FilterIterator<T> {
	
	var iter:Iterator<T>;
	var f:T->Bool;
	var upcoming:Option<T> = None;
	
	public function new(iter, f) {
		this.iter = iter;
		this.f = f;
		prepareNext();
	}
		
	public inline function hasNext() {
		return upcoming != None;
	}
		
	public function next() {
		return switch upcoming {
			case None:
				null;
			case Some(v):
				prepareNext();
				v;
		}
	}
	
	function prepareNext() {
		while(iter.hasNext()) {
			var item = iter.next();
			if(f(item)) {
				upcoming = Some(item);
				return;
			}
		}
		upcoming = None;
	}
}

class MapSequence<T, A> implements SequenceObject<A> {
	var seq:Sequence<T>;
	var f:T->A;
	
	public function new(seq, f) {
		this.seq = seq;
		this.f = f;
	}
	
	public inline function iterator():Iterator<A>
		return new MapIterator(seq.iterator(), f);
}

class MapIterator<T, A> {
	
	var iter:Iterator<T>;
	var f:T->A;
	
	public function new(iter, f) {
		this.iter = iter;
		this.f = f;
	}
	
	public inline function hasNext():Bool
		return iter.hasNext();
		
	public inline function next():A
		return f(iter.next());
}
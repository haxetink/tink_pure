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
	
	public inline function slice(start:Int, ?end:Int):Sequence<T>
		return new SlicedSequence(this, start, end);
		
	public inline function reverse():Sequence<T>
		return new ReversedSequence(this);
	
	public inline function empty():Bool
		return Lambda.empty(toIterable());
	
	public inline function exists(f:Filter<T>):Bool
		return Lambda.exists(toIterable(), f);
	
	@:impl // https://github.com/HaxeFoundation/haxe/issues/6157
	public static inline function flatten<T>(seq:SequenceObject<Sequence<T>>):Sequence<T>
		return nested(seq);
	
	public static inline function nested<T>(seq:Sequence<Sequence<T>>):Sequence<T>
		return new NestedSequence(seq);
	
	public inline function find(f:Filter<T>):T
		return Lambda.find(toIterable(), f);
	
	public inline function count(?f:Filter<T>):Int
		return Lambda.count(toIterable(), f);
	
	public inline function fold<A>(f:T->A->A, first:A):A
		return Lambda.fold(toIterable(), f, first);
	
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

private class IterableSequence<T> implements SequenceObject<T> {
	var iterable:Iterable<T>;
	public function new(iterable)
		this.iterable = iterable;
	public inline function iterator():Iterator<T>
		return iterable.iterator();
}

private class ReversedSequence<T> implements SequenceObject<T> {
	var seq:Sequence<T>;
	var reversed:Array<T>;
	
	public function new(seq)
		this.seq = seq;
		
	public function iterator():Iterator<T> {
		if(reversed == null) {
			// TODO: currently the underlying sequence is completely iterated at once,
			// need to figure out how to make it per-item lazy, if even possible
			reversed = seq.toArray();
			reversed.reverse();
		}
		return reversed.iterator();
	}
}

private class NestedSequence<T> implements SequenceObject<T> {
	var seq:Sequence<Sequence<T>>;
	
	public function new(seq)
		this.seq = seq;
		
	public function iterator():Iterator<T>
		return new NestedIterator(seq.iterator());
}

private class NestedIterator<T> {
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

private class SlicedSequence<T> implements SequenceObject<T> {
	public var seq:Sequence<T>;
	var start:Int;
	var end:Null<Int>;
	
	public function new(seq, start, end) {
		this.seq = seq;
		this.start = start;
		this.end = end;
	}
	
	public function iterator():Iterator<T>
		return new SlicedIterator(seq.iterator(), start, end);
} 

private class SlicedIterator<T> {
	public var iter:Iterator<T>;
	var start:Int;
	var end:Null<Int>;
	var pos = 0;
	var prepared = false;
	
	public function new(iter, start, end) {
		this.iter = iter;
		this.start = start;
		this.end = end;
	}
	
	public function hasNext() {
		prepare();
		return end != null && pos >= end ? false : iter.hasNext();
	}
	
	public function next() {
		prepare();
		return end != null && pos++ >= end ? null : iter.next();
	}
	
	function prepare() {
		if(prepared) return;
		prepared = true;
		while(pos < start) {
			if(iter.hasNext()) iter.next();
			else break;
			pos++;
		}
	}
} 

private class SingleSequence<T> implements SequenceObject<T> {
	var item:T;
	
	public inline function new(item)
		this.item = item;
		
	public inline function iterator():Iterator<T>
		return new SingleIterator(item);
}

private class SingleIterator<T> {
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

private class CachedSequence<T> implements SequenceObject<T> {
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

private class FilterSequence<T> implements SequenceObject<T> {
	var seq:Sequence<T>;
	var f:T->Bool;
	
	public function new(seq, f) {
		this.seq = seq;
		this.f = f;
	}
	
	public inline function iterator():Iterator<T>
		return new FilterIterator(seq.iterator(), f);
}

enum Upcoming<T> {
	Unknown;
	None;
	Some(v:T);
}
private class FilterIterator<T> {
	
	var iter:Iterator<T>;
	var f:T->Bool;
	var upcoming:Upcoming<T> = Unknown;
	
	public function new(iter, f) {
		this.iter = iter;
		this.f = f;
	}
		
	public inline function hasNext() {
		return switch upcoming {
			case Some(v):
				true;
			case None:
				false;
			case Unknown:
				advance();
				hasNext();
		}
	}
		
	public function next() {
		return switch upcoming {
			case Some(v):
				upcoming = Unknown;
				v;
			case None:
				null;
			case Unknown:
				advance();
				next();
		}
	}
	
	function advance() {
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

private class MapSequence<T, A> implements SequenceObject<A> {
	var seq:Sequence<T>;
	var f:T->A;
	
	public function new(seq, f) {
		this.seq = seq;
		this.f = f;
	}
	
	public inline function iterator():Iterator<A>
		return new MapIterator(seq.iterator(), f);
}

private class MapIterator<T, A> {
	
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
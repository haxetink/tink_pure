package tink.pure;

using tink.CoreApi;

abstract Sequence<T>(SequenceObject<T>) from SequenceObject<T> {
	
	@:from
	public static function ofSingle<T>(v:T):Sequence<T>
		return new SingleSequence(v);
		
	@:from
	public static function ofIterable<T>(v:Iterable<T>):Sequence<T>
		return cast v;
		
	@:to
	public inline function iterator():Iterator<T>
		return this == null ? EmptyIterator.inst : this.iterator();
		
	@:to
	public function asIterable():Iterable<T>
		return this == null ? EmptySequence.inst : this;
		
	@:to
	public function asArray():Array<T>
		return [for(i in this) i];
		
	public function map<A>(f:T->A):Sequence<A>
		return new CachedSequence(new MapSequence(this, f));
	
	public function filter(f:T->Bool):Sequence<T>
		return new CachedSequence(new FilterSequence(this, f));
	
	public inline function concat(other:Sequence<T>):Sequence<T>
		return new ConcatSequence(this, other);
	
	public inline function find(f:T->Bool):T
		return Lambda.find(asIterable(), f);
	
	public inline function exists(f:T->Bool):Bool
		return Lambda.exists(asIterable(), f);
	
	public inline function count(?f:T->Bool):Int
		return Lambda.count(asIterable(), f);
}

interface SequenceObject<T> {
	function iterator():Iterator<T>;
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
	var seq:Sequence<T>;
	var cache:Array<T>;
	var iter:Iterator<T>;
	var finished = false;
	
	public function new(seq:Sequence<T>) {
		this.seq = seq;
		iter = seq.iterator();
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

class ConcatSequence<T> implements SequenceObject<T> {
	var a:Iterable<T>;
	var b:Iterable<T>;
	
	public function new(a, b) {
		this.a = a;
		this.b = b;
	}
	
	public function iterator():Iterator<T>
		return new ConcatIterator(a.iterator(), b.iterator());
}

class ConcatIterator<T> {
	var a:Iterator<T>;
	var b:Iterator<T>;
	var current:Iterator<T>;
	
	public function new(a, b) {
		this.a = a;
		this.b = b;
		current = a;
	}
	
	public function hasNext() {
		return switch current.hasNext() {
			case false if(current == a):
				current = b;
				current.hasNext();
			case v: v;
		}
	}
	
	public inline function next()
		return current.next();
}

class FilterSequence<T> implements SequenceObject<T> {
	var iter:Iterable<T>;
	var f:T->Bool;
	
	public function new(iter, f) {
		this.iter = iter;
		this.f = f;
	}
	
	public inline function iterator():Iterator<T>
		return new FilterIterator(iter.iterator(), f);
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
	var iter:Iterable<T>;
	var f:T->A;
	
	public function new(iter, f) {
		this.iter = iter;
		this.f = f;
	}
	
	public inline function iterator():Iterator<A>
		return new MapIterator(iter.iterator(), f);
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
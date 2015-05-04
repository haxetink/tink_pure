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
	
	public inline function iterator():NodeIterator<T>
		return new NodeIterator(this);
		
	public function filter(f:T->FilterResult) 
		return 
			if (this == null) null;
			else this.filter(f);
			
	@:from static public function fromArray<A>(i:Array<A>):List<A> {
		var ret = null,
				len = 0;
		for (i in i)
			ret = new Node(++len, i, [ret]);
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
		this.tails = tails == null ? EMPTY : tails;
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
	static var EMPTY = [];
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
		
	public inline function next():T {
		var next = list.pop();
		
		for (i in -next.tails.length...0)
			list.push(next.tails[ -i - 1]);

		return next.value;
	}
}
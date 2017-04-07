package;

import tink.pure.Sequence;
import tink.unit.*;
import tink.unit.Assert.assert;

@:asserts
class TestSequence {
	public function new() {}
	
	public function map() {
		var s:Sequence<Int> = [for(i in 1...4) i];
		var i = 0;
		
		// make mapper only ever run once
		s = s.map(function(v) {
			i++;
			return v * v;
		});
		
		asserts.assert(i == 0);
		
		var j = 0;
		for(_ in s) asserts.assert(i == ++j);
		
		var j = 0;
		for(_ in s) j++;
		for(_ in s) j++;
		for(_ in s) j++;
		
		asserts.assert(i == 3);
		asserts.assert(j == 9);
		
		var i = 1;
		for(v in s)
			asserts.assert(v == i * i++);
		return asserts.done();
	}
	
	public function filter() {
		var s:Sequence<Int> = [for(i in 1...11) i];
		var check = [2,4,6,8,10];
		var i = 0;
		
		// make filter only ever run once
		s = s.filter(function(v) {
			i++;
			return v % 2 == 0;
		});
		
		asserts.assert(i == 0);
		
		var j = 0;
		for(_ in s) j++;
		for(_ in s) j++;
		for(_ in s) j++;
		
		asserts.assert(i == 10);
		asserts.assert(j == 15);
		
		var i = 0;
		for(v in s.filter(function(v) return v % 2 == 0))
			asserts.assert(v == check[i++]);
		
		return asserts.done();
	}
	
	public function nil() {
		var s:Sequence<Int> = null;
		var i = 0;
		for(v in s) i++;
		asserts.assert(i == 0);
		asserts.assert(s.count() == 0);
		asserts.assert(s.empty());
		asserts.assert(!s.exists(2));
		asserts.assert(s.toArray().length == 0);
		return asserts.done();
	}
	
	public function single() {
		var s:Sequence<Int> = 2;
		var i = 0;
		for(v in s) i++;
		asserts.assert(i == 1);
		asserts.assert(s.count() == 1);
		asserts.assert(!s.empty());
		asserts.assert(s.exists(2));
		asserts.assert(s.toArray().length == 1);
		return asserts.done();
	}
	
	public function concat() {
		var s1:Sequence<Int> = [1, 2, 3, 4, 5];
		var s2:Sequence<Int> = [6, 7, 8, 9, 10];
		var s = s1.concat(s2);
		var i = 0;
		for(v in s) i += v;
		asserts.assert(i == 55);
		asserts.assert(s.count() == 10);
		asserts.assert(!s.empty());
		asserts.assert(s.exists(2));
		asserts.assert(s.toArray().length == 10);
		return asserts.done();
	}
	
	public function exists() {
		var s1:Sequence<Int> = [1, 2, 3, 4, 5];
		var s2:Sequence<Int> = [6, 7, 8, 9, 10];
		var s = s1.concat(s2);
		var size = s.count();
		for(i in 1...size + 2)
			asserts.assert(s.exists(function(v) return v == i) == (i <= size));
		return asserts.done();
	}
	
	public function nested() {
		var s1:Sequence<Int> = [1, 2, 3];
		var s2:Sequence<Int> = [4, 5];
		var s3:Sequence<Int> = [6, 7, 8, 9, 10];
		var s:Sequence<Sequence<Int>> = [s1, s2, s3];
		var sum = 0;
		for(i in s.flatten()) sum += i;
		return assert(sum == 55);
	}
	
	public function complex() {
		var s1:Sequence<Int> = [for(i in 0...50) i];
		var s2:Sequence<Int> = [for(i in 50...99) i];
		var s3:Sequence<Int> = 99;
		var s4:Sequence<Int> = null;
		
		var r = Sequence.nested([s1, s2, s3, s4])
			.filter(function(v) return v % 2 == 0)
			.map(function(v) return v * v)
			.concat([1,2,3])
			.filter(function(v) return v < 50)
			.join(',');
		
		return assert(r == '0,4,16,36,1,2,3');
	}
	
	public function purity() {
		var a = [for(i in 0...100) i];
		var s:Sequence<Int> = a;
		
		asserts.assert(s.count() == 100);
		a.push(101);
		asserts.assert(s.count() == 100);
		return asserts.done();
	}
	
	@:variant(100, 20, 10, 145)
	@:variant(15, 20, 5, 60)
	@:variant(5, 20, 0, 0)
	@:variant(100, null, 90, 4905)
	@:variant(15, null, 5, 60)
	@:variant(5, null, 0, 0)
	public function slice(items:Int, end:Null<Int>, count:Int, sum:Int) {
		var s:Sequence<Int> = [for(i in 0...items) i];
		var sliced = s.slice(10, end);
		asserts.assert(sliced.count() == count);
		asserts.assert(sliced.fold(function(i, sum) return i + sum, 0) == sum);
		return asserts.done();
	}
	
	public function reverse() {
		var items = 10;
		var s:Sequence<Int> = [for(i in 0...items) i];
		var i = 0;
		for(v in s.reverse()) asserts.assert(v == items - ++i);
		return asserts.done();
	}
}
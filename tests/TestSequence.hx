package;

import tink.pure.Sequence;
import tink.unit.*;
import tink.unit.Assert.assert;

class TestSequence {
	public function new() {}
	
	public function map(buffer:AssertionBuffer) {
		var s:Sequence<Int> = [for(i in 1...4) i];
		var i = 0;
		var j = 0;
		
		// make mapper only ever run once
		s = s.map(function(v) {
			i++;
			return v * v;
		});
		
		for(_ in s) j++;
		for(_ in s) j++;
		for(_ in s) j++;
		
		buffer.assert(i == 3);
		buffer.assert(j == 9);
		
		var i = 1;
		for(v in s)
			buffer.assert(v == i * i++);
		return buffer.done();
	}
	
	public function filter(buffer:AssertionBuffer) {
		var s:Sequence<Int> = [for(i in 1...11) i];
		var check = [2,4,6,8,10];
		var i = 0;
		var j = 0;
		
		// make filter only ever run once
		s = s.filter(function(v) {
			i++;
			return v % 2 == 0;
		});
		
		for(_ in s) j++;
		for(_ in s) j++;
		for(_ in s) j++;
		
		buffer.assert(i == 10);
		buffer.assert(j == 15);
		
		var i = 0;
		for(v in s.filter(function(v) return v % 2 == 0))
			buffer.assert(v == check[i++]);
		
		return buffer.done();
	}
	
	public function nil(buffer:AssertionBuffer) {
		var s:Sequence<Int> = null;
		var i = 0;
		for(v in s) i++;
		buffer.assert(i == 0);
		buffer.assert(s.count() == 0);
		buffer.assert(s.empty());
		buffer.assert(!s.exists(2));
		buffer.assert(s.toArray().length == 0);
		return buffer.done();
	}
	
	public function single(buffer:AssertionBuffer) {
		var s:Sequence<Int> = 2;
		var i = 0;
		for(v in s) i++;
		buffer.assert(i == 1);
		buffer.assert(s.count() == 1);
		buffer.assert(!s.empty());
		buffer.assert(s.exists(2));
		buffer.assert(s.toArray().length == 1);
		return buffer.done();
	}
	
	public function concat(buffer:AssertionBuffer) {
		var s1:Sequence<Int> = [1, 2, 3, 4, 5];
		var s2:Sequence<Int> = [6, 7, 8, 9, 10];
		var s = s1.concat(s2);
		var i = 0;
		for(v in s) i += v;
		buffer.assert(i == 55);
		buffer.assert(s.count() == 10);
		buffer.assert(!s.empty());
		buffer.assert(s.exists(2));
		buffer.assert(s.toArray().length == 10);
		return buffer.done();
	}
	
	public function exists(buffer:AssertionBuffer) {
		var s1:Sequence<Int> = [1, 2, 3, 4, 5];
		var s2:Sequence<Int> = [6, 7, 8, 9, 10];
		var s = s1.concat(s2);
		var size = s.count();
		for(i in 1...size + 2)
			buffer.assert(s.exists(function(v) return v == i) == (i <= size));
		return buffer.done();
	}
	
	public function nested(buffer:AssertionBuffer) {
		var s1:Sequence<Int> = [1, 2, 3];
		var s2:Sequence<Int> = [4, 5];
		var s3:Sequence<Int> = [6, 7, 8, 9, 10];
		var s:Sequence<Sequence<Int>> = [s1, s2, s3];
		var sum = 0;
		for(i in s._flatten()) sum += i;
		return assert(sum == 55);
	}
	
	public function complex(buffer:AssertionBuffer) {
		var s1:Sequence<Int> = [for(i in 0...50) i];
		var s2:Sequence<Int> = [for(i in 50...99) i];
		var s3:Sequence<Int> = 99;
		var s4:Sequence<Int> = null;
		
		var r = Sequence.flatten([s1, s2, s3, s4])
			.filter(function(v) return v % 2 == 0)
			.map(function(v) return v * v)
			.concat([1,2,3])
			.filter(function(v) return v < 50)
			.join(',');
		
		return assert(r == '0,4,16,36,1,2,3');
	}
	
	public function purity(buffer:AssertionBuffer) {
		var a = [for(i in 0...100) i];
		var s:Sequence<Int> = a;
		
		buffer.assert(s.count() == 100);
		a.push(101);
		buffer.assert(s.count() == 100);
		return buffer.done();
	}
	
	@:variant(100, 20, 10, 145)
	@:variant(15, 20, 5, 60)
	@:variant(5, 20, 0, 0)
	@:variant(100, null, 90, 4905)
	@:variant(15, null, 5, 60)
	@:variant(5, null, 0, 0)
	public function slice(items:Int, end:Null<Int>, count:Int, sum:Int, buffer:AssertionBuffer) {
		var s:Sequence<Int> = [for(i in 0...items) i];
		var sliced = s.slice(10, end);
		buffer.assert(sliced.count() == count);
		buffer.assert(sliced.fold(function(i, sum) return i + sum, 0) == sum);
		return buffer.done();
	}
}
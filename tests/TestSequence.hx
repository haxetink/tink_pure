package;

import tink.pure.Sequence;
import tink.unit.*;
import tink.unit.Assert.assert;

class TestSequence {
	public function new() {}
	
	public function map(buffer:AssertionBuffer) {
		var s:Sequence<Int> = [for(i in 1...4) i];
		var i = 1;
		for(v in s.map(function(v) return v * v))
			buffer.assert(v == i * i++);
		return buffer.done();
	}
	
	public function filter(buffer:AssertionBuffer) {
		var s:Sequence<Int> = [for(i in 1...11) i];
		var check = [2,4,6,8,10];
		var i = 0;
		var j = 0;
		
		// TODO: make sure lazy, and don't re-run
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
		return buffer.done();
	}
	
	public function single(buffer:AssertionBuffer) {
		var s:Sequence<Int> = 2;
		var i = 0;
		for(v in s) i++;
		buffer.assert(i == 1);
		buffer.assert(s.count() == 1);
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
		for(i in s.flatten()) sum += i;
		return assert(sum == 55);
	}
	
	public function complex(buffer:AssertionBuffer) {
		var s:Sequence<Int> = [for(i in 0...100) i];
		
		var r = s
			.filter(function(v) return v % 2 == 0)
			.map(function(v) return v * v)
			.concat([1,2,3])
			.filter(function(v) return v < 50)
			.join(',');
		
		return assert(r == '0,4,16,36,1,2,3');
	}
}
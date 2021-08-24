package ;

import tink.core.Pair;
import tink.pure.Dict;

@:asserts
class DictTest {
  public function new() {}
  public function basics() {
    var m:Map<Int, String> = [];
    
    var d:Dict<Int, String> = m;
    var d:Dict<Int, String> = [];
    var d:Dict<Int, String> = new Map();
    var d:Dict<Int, String> = [1 => 'foo'];
    
    var d:Dict<Int, String> = [for (i in 0...5) i => 'v$i'];
    function expect(s, d:Dict<Int, String>, ?pos) {
      var list = [for (k => v in d) '$k => $v'];
      list.sort(Reflect.compare);
      asserts.assert(s == list.join(', '), pos);
    }

    expect('0 => v0, 1 => v1, 2 => v2, 3 => v3, 4 => v4', d);
    expect('2 => x, 3 => v3, 4 => v4, 5 => y', d.with([2 => 'x', 5 => 'y']).without([0, 1]));
    expect('1 => v1, 2 => x, 3 => v3, 4 => v4', d.with(2, 'x').without(0));
    expect('3 => v3, 4 => v4', d.filter(entry -> entry.key > 2));
    return asserts.done();
  }
  
  public function literal() {
    var d1:Dict<Int, String> = [];
    var d2 = d1.with(1, 'foo');
    asserts.assert(d1 != d2);
    return asserts.done();
  }
  
  public function count() {
    var d1:Dict<Int, String> = [];
    asserts.assert(d1.count() == 0);
    
    var d2 = d1.with(1, 'foo');
    asserts.assert(d2.count() == 1);
    asserts.assert(d2.count(v -> v == 'foo') == 1);
    asserts.assert(d2.count(v -> v == 'bar') == 0);
    
    return asserts.done();
  }
  
  public function exists() {
    var d1:Dict<Int, String> = [];
    asserts.assert(!d1.exists(v -> true));
    
    var d2 = d1.with(1, 'foo');
    asserts.assert(d2.exists(v -> v == 'foo'));
    asserts.assert(!d2.exists(v -> v == 'bar'));
    
    return asserts.done();
  }
  
  public function iterators() {
    var d1:Dict<String, Int> = ['foo' => 1];
    asserts.assert(d1.fold((v, total) -> v + total, 0) == 1);
    asserts.assert([for(v in d1) v][0] == 1);
    asserts.assert([for(k => v in d1) k][0] == 'foo');
    asserts.assert([for(k => v in d1) v][0] == 1);
    return asserts.done();
  }

  #if tink_json
  public function json() {
    var d:Dict<Int, String> = [for (i in 0...5) i => 'v$i'];
    var d2 = d;
    d2 = tink.Json.parse(tink.Json.stringify(d));
    for (k => v in d)
      asserts.assert(v == d2[k]);
    return asserts.done();
  }
  #end
}
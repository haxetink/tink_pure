import tink.pure.List;

import tink.unit.Assert.assert;

@:asserts
class ListTest {
  public function new() {}
	
  public function prepend() {
    var list = List.fromArray([1,2]);
    list = list.prepend(0);
    var i = 0;
    for(item in list) asserts.assert(item == i++);
    return asserts.done();
  }
  
  public function append() {
    var list = List.fromArray([0,1]);
    list = list.append(2);
    var i = 0;
    for(item in list) asserts.assert(item == i++);
    return asserts.done();
  }
  
  public function single() {
    var list = List.single(1);
    return assert(list.length == 1);
  }
  
  public function first() {
    var list = List.fromArray([1,2,3,4]);
    asserts.assert(list.first().match(Some(1)));
    asserts.assert(list.first(function(v) return v % 2 == 0).match(Some(2)));
    asserts.assert(list.first(function(v) return v > 5).match(None));
    return asserts.done();
  }
  
  public function last() {
    var list = List.fromArray([1,2,3,4]);
    asserts.assert(list.last().match(Some(4)));
    asserts.assert(list.last(function(v) return v % 2 == 0).match(Some(4)));
    asserts.assert(list.last(function(v) return v > 5).match(None));
    return asserts.done();
  }
  
  public function get() {
    var list = List.fromArray([1,2]);
    asserts.assert(list.get(-1).match(None));
    asserts.assert(list.get(0).match(Some(1)));
    asserts.assert(list.get(1).match(Some(2)));
    asserts.assert(list.get(3).match(None));
    return asserts.done();
  }
  
  public function sort() {
    var list = List.fromArray([3,4,1,2]);
    var sorted = list.sort(Reflect.compare);
    asserts.assert(sorted.first().match(Some(1)));
    asserts.assert(sorted.last().match(Some(4)));
    return asserts.done();
  }
  
  public function replace() {
    var list = List.fromArray([1,2,1,3,1,4]);
    list = list.replace(1, 5);
    return assert(list.toArray().join(',') == '5,2,5,3,5,4');
  }
  
  #if tink_json
  public function json() {
    var list = List.fromArray([1,2,3,4]);
    var str = tink.Json.stringify(list);
    asserts.assert(str == '[1,2,3,4]');
    var parsed:List<Int> = tink.Json.parse(str);
    var i = 0;
    for(v in parsed) asserts.assert(v == ++i);
    return asserts.done();
  }
  #end
}

import tink.pure.Mapping;

import tink.unit.Assert.assert;

@:asserts
class MappingTest {
  public function new() {}
	
  #if tink_json
  public function json() {
    var map:Mapping<Int, String> = [1 => 'a', 2 => 'b'];
    
    var s:String = tink.Json.stringify(map);
    // asserts.assert(s == '[{"condensed":[[1,"a"],[2,"b"]],"isset":false,"key":null,"value":null}]'); // the order seems indeterminate
    
    map = tink.Json.parse(s);
    asserts.assert([for(key in map.keys()) key].length == 2);
    asserts.assert(map.get(1) == 'a');
    asserts.assert(map.get(2) == 'b');
    
    return asserts.done();
  }
  #end
}
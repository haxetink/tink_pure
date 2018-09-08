import tink.pure.Mapping;

import tink.unit.Assert.assert;

@:asserts
class MappingTest {
  public function new() {}
	
  #if tink_json
  public function json() {
    var map:Mapping<Int, String> = [1 => 'a', 2 => 'b'];
    
    asserts.assert(tink.Json.stringify(map) == '[{"condensed":[[1,"a"],[2,"b"]],"isset":false,"key":null,"value":null}]');
    
    return asserts.done();
  }
  #end
}
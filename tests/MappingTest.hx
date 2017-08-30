import tink.pure.Mapping;

import tink.unit.Assert.assert;

@:asserts
class MappingTest {
  public function new() {}
	
  #if tink_json
  public function json() {
    var map:Mapping<Int, String> = [1 => 'a', 2 => 'b'];
    
    // TODO:
    // var str = tink.Json.stringify(map);
    // trace(str);
    
    return asserts.done();
  }
  #end
}
package ;

import tink.testrunner.*;
import tink.unit.*;
import tink.unit.Assert.assert;
import travix.Logger.*;
import tink.pure.List;
import tink.pure.Mapping;

class RunTests {
  public function new() {}

  @:describe("Mapping.rAddMutable")
  @:variant(['foo' => 5], ['bar' => 6], ['foo' => 5, 'bar' => 6])
  @:variant(['foo' => 5], ['foo' => 6], ['foo' => 6])
  public function rAddMutable(a:Mapping<String, Int>, b:Map<String, Int>, expected:Map<String, Int>) {
    
    var sum:Map<String, Int> = a + b;
    return [
      for (m in [expected, sum])
        for (e in m.keys())
          assert(expected[e] == sum[e])
    ];
    
  }
  
  

  static function main() 
    Runner.run(TestBatch.make([
      new RunTests(),
      new TestSequence(),
    ])).handle(function(result) {
      exit(result.summary().failures.length);
    });    
  
}

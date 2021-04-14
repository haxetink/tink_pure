package ;

import tink.core.Pair;
import tink.pure.Dict;

@:asserts
class DictTest {
  public function new() {}
  public function basics() {
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
    asserts.assert(Lambda.count({iterator: d1.iterator}) == 0);
    var d2 = d1.with(1, 'foo');
    asserts.assert(Lambda.count({iterator: d1.iterator}) == 0);
    asserts.assert(Lambda.count({iterator: d2.iterator}) == 1);
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
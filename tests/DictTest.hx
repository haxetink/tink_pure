package ;

import tink.core.Pair;
import tink.pure.Dict;

@:asserts
class DictTest {
  public function new() {}
  @:include public function test() {
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
}
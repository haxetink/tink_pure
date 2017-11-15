import tink.pure.Slice;

@:asserts
class SliceTest {
  public function new() {}
  public function basic() {
    var a = [for (i in 0...100) i];
    var s:Slice<Int> = a;
    asserts.assert(s.length == a.length);
    for (i in 0...a.length)
      asserts.assert(s[i] == a[i]);
    return asserts.done();
  }
}
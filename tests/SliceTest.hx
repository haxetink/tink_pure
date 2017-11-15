import tink.pure.Slice;

@:asserts
class SliceTest {
  public function new() {}
  public function basic() {
    var a = [for (i in 0...100) i];
    var s:Slice<Int> = a;
    var rev = s.reverse();
    asserts.assert(s.length == a.length);
    for (i in 0...a.length) {
      asserts.assert(s[i] == a[i]);
      asserts.assert(rev[a.length - i - 1] == a[i]);
    }
    return asserts.done();
  }
}
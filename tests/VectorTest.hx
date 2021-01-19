import tink.pure.Vector;

@:asserts
class VectorTest {
  public function new() {}
  public function basic() {
    var a = [1, 2, 3, 4];
    var v = Vector.fromArray(a);
    a[0] = 0;
    asserts.assert(v[0] == 1);
    v = 0 & v;
    asserts.assert(v.length == 5);
    asserts.assert(v[0] == 0);
    return asserts.done();
  }

  public function casts() {
    var a = [1, 2, 3, 4];
    var v:Vector<Float> = (a:Vector<Int>);
    var v:Vector<Float> = a;
    return asserts.done();
  }

  public function with() {
    var a:Vector<Int> = [1, 2, 3, 4];
    final b = a.with(0, 5);
    asserts.assert(b.length == 4);
    asserts.assert(b[0] == 5);
    asserts.assert(b[1] == 2);
    asserts.assert(b[2] == 3);
    asserts.assert(b[3] == 4);
    return asserts.done();
  }
}
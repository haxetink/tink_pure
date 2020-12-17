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
}
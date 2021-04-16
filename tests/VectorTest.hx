import tink.pure.Vector;

@:asserts
class VectorTest {
  public function new() {}
  
  public function init() {
    var v1:Vector<Int> = [];
    var v2:Vector<Int> = [1,2,3];
    var v3:Vector<Int> = [for(i in 0...3) i];
    var v4:Vector<Int> = new Array();
    // trace(v1, v2, v3, v4);
    return asserts.done();
  }
  
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
    
    var v:Vector<{final foo:Int;}> = [{foo: 1}];
    var v:Vector<{final foo:Int;}> = [for(i in 0...10) {foo: i}];
    // asserts.expectCompilerError((v:Vector<{var foo:Int;}>)); // FIXME: https://github.com/HaxeFoundation/haxe/issues/10198
    
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

  public function fold() {
    var a:Vector<Int> = [1, 2, 3, 4];
    asserts.assert(a.fold((v, sum) -> sum + v, 0) == 10);
    return asserts.done();
  }
  
  public function comprehension() {
    var a:Vector<Int> = [for(i in 0...10) if(i == 0) 10 else if(i < 4) i];
    asserts.assert(a.length == 4);
    asserts.assert(a[0] == 10);
    asserts.assert(a[1] == 1);
    asserts.assert(a[2] == 2);
    asserts.assert(a[3] == 3);
    return asserts.done();
  }
  
  public function comprehensionEmulation() {
    var b:Array<Int>;
    var a:Vector<Int> = { // this block emulates the compiler generated exprs of an array comprehension
      var v = [];
      {b = v;}
      v;
    }
    b.push(5);
    asserts.assert(a.length == 0);
    return asserts.done();
  }
}
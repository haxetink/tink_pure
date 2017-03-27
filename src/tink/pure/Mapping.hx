package tink.pure;

@:structInit private class MapEntry<K, V> {
  public var key(default, never):K;
  public var isset(default, never):Bool;
  public var value(default, never):V;
  public var condensed:Map<K, V>;
}

@:pure abstract Mapping<K, V>(List<MapEntry<K, V>>) from List<MapEntry<K, V>> to List<MapEntry<K, V>> {
  
  public inline function new() this = null;
  
  public function exists(key:K) {
    for (p in this)
      if (p.key == key) return p.isset;
      else if (p.condensed != null) return p.condensed.exists(key);
    return false;
  }
  
  @:arrayAccess public function get(key:K) {
    for (p in this)
      if (p.key == key) return p.value;
      else if (p.condensed != null) return p.condensed.get(key);
    return null;
  }
  
  public function without(key:K) 
    return this.prepend({ key: key, isset: false, value: null, condensed: null });
  
  public function with(key:K, value:V):Mapping<K, V> 
    return this.prepend({ key: key, isset: true, value: value, condensed: null });

  //Everything beyond this point is for the brave
  @:extern inline public function iterator()
    return toMutable().iterator();

  @:extern inline public function keys()
    return toMutable().keys();

  @:to @:extern inline function toMutable():Map<K, V>
    return switch this.first() {
      case None: new Map();
      case Some({ condensed: c }) if (c != null): c;
      case Some(first):

        var ret = new Map<K, V>();
        var excluded = new Map<K, Bool>();

        for (entry in this)
          switch entry.condensed {
            case null: 
              if (!ret.exists(entry.key) && !excluded.exists(entry.key)) {
                if (entry.isset) ret[entry.key] = entry.value;
                else excluded[entry.key] = true;
              }
            case c:
              for (k in c.keys()) if (!excluded.exists(k)) ret.set(k, c[k]);
              break;
          }

        return first.condensed = ret;
    }

  @:extern inline static function merge<K, V>(a:Array<Map<K, V>>) 
    return [for (m in a) for (k in m.keys()) k => m[k]];

  @:from @:extern inline static function ofMutable<K, V>(v:Map<K, V>):Mapping<K, V> {
    var ret = new List<MapEntry<K, V>>();
    var first = true;

    for (k in v.keys())
      ret = ret.prepend({ key: k, isset: true, value: v[k], condensed: if (first == true) { first = false; merge([v]); } else null });
    
    return ret;
  }

  @:op(a + b) @:extern inline static function rAddMutable<K, V>(m:Mapping<K, V>, other:Map<K, V>):Mapping<K, V> 
    return merge([m, other]);

  @:op(a + b) @:extern inline static function lAddMutable<K, V>(other:Map<K, V>, m:Mapping<K, V>):Mapping<K, V> 
    return merge([other, m]);

}
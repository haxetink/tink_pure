package tink.pure;

using tink.CoreApi;

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
      if (p.condensed != null) return p.condensed.exists(key);
      else if (p.key == key) return p.isset;
    
    return false;
  }
  
  @:arrayAccess public function get(key:K) {

    for (p in this)
      if (p.condensed != null) return p.condensed.get(key);
      else if (p.key == key) return p.value;

    return null;
  }
  
  public function without(key:K) 
    return this.prepend({ key: key, isset: false, value: null, condensed: null });
  
  public function with(key:K, value:V):Mapping<K, V> 
    return this.prepend({ key: key, isset: true, value: value, condensed: null });

  @:extern inline function alloc():Map<K, V> return new Map();

  //Everything beyond this point is for the brave
  @:extern inline public function iterator()
    return getCondensed().or(alloc).iterator();

  @:extern inline public function keys()
    return getCondensed().or(alloc).keys();

  @:to @:extern inline public function condensed():Mapping<K, V>
    return switch getCondensed() {
      case None: null;
      case Some(v): v;
    }

  @:to @:extern inline function getCondensed() {
    return switch this.first() {
      case None: None;
      case Some({ condensed: c }) if (c != null): Some(c);
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
              for (k in c.keys()) if (!excluded.exists(k) && !ret.exists(k)) ret.set(k, c[k]);
              break;
          }

        return Some(first.condensed = ret);
    }
  }

  @:to @:extern inline function toMutable():Map<K, V>
    return getCondensed().map(function (m) return merge([m])).or(alloc);

  @:extern inline static function merge<K, V>(a:Array<Map<K, V>>) 
    return [for (m in a) for (k in m.keys()) k => m[k]];

  @:from @:extern inline static function ofMutable<K, V>(v:Map<K, V>):Mapping<K, V> {
    var ret = new List<MapEntry<K, V>>();
    
    return
      if (v.iterator().hasNext()) 
        ret.prepend({ key: null, isset: false, value: null, condensed: merge([v]) });
      else ret;
  }

  @:op(a + b) @:extern inline static function rAddMutable<K, V>(m:Mapping<K, V>, other:Map<K, V>):Mapping<K, V> 
    return merge([m, other]);

  @:op(a + b) @:extern inline static function lAddMutable<K, V>(other:Map<K, V>, m:Mapping<K, V>):Mapping<K, V> 
    return merge([other, m]);
    
  #if tink_json
  
  // TODO: seems that @:multiType is preventing the below to work
  
  // @:to function toRepresentation():tink.json.Representation<Map<K, V>> 
  //   return new tink.json.Representation(toMutable());
    
  // @:from static function ofRepresentation<K, V>(rep:tink.json.Representation<Map<K, V>>)
  //   return Mapping.ofMutable(rep.get());
    
  #end

}
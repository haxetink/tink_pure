package tink.pure;

using tink.CoreApi;

private typedef MapEntry<K, V> = {
  var key(default, never):K;
  var isset(default, never):Bool;
  var value(default, never):Null<V>;
  var condensed:Null<Map<K, V>>;
}

@:pure abstract Mapping<K, V>(List<MapEntry<K, V>>) from List<MapEntry<K, V>> to List<MapEntry<K, V>> {
  
  public inline function new() this = null;
  
  /**
    Returns true if `key` has a mapping, false otherwise.
  **/
  public function exists(key:K) {

    for (p in this)
      if (p.condensed != null) return p.condensed.exists(key);
      else if (p.key == key) return p.isset;
    
    return false;
  }
  
  /**
    Returns the value for `key`.
  **/
  @:arrayAccess public function get(key:K) {

    for (p in this)
      if (p.condensed != null) return p.condensed.get(key);
      else if (p.key == key) return p.value;

    return null;
  }
  
  /**
    Clone this `Mapping` but without the specified key
  **/
  public function without(key:K) 
    return this.prepend({ key: key, isset: false, value: null, condensed: null });
  
  /**
    Clone this `Mapping` and add the specified key-value pair
  **/
  public function with(key:K, value:V):Mapping<K, V> 
    return this.prepend({ key: key, isset: true, value: value, condensed: null });

  @:extern inline function alloc():Map<K, V> return new Map();

  //Everything beyond this point is for the brave
  
  /**
   *  Returns an Iterator over the values of `this` Mapping.
   */
  @:extern inline public function iterator()
    return getCondensed().or(alloc).iterator();

  /**
   *  Returns an Iterator over the keys of `this` Mapping.
   */
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
  
  @:to inline function toRepresentation():tink.json.Representation<Array<MapEntry<K, V>>>
    // TODO: maybe condense first?
    return @:privateAccess this.toRepresentation();
    
  @:from static function ofRepresentation<K, V>(rep:tink.json.Representation<Array<MapEntry<K, V>>>):Mapping<K, V>
    return @:privateAccess List.ofRepresentation(rep);
    
  #end

}
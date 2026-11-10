extends RefCounted
const LABELS={"common":"일반","fine":"양품","great":"대성공"}
static func prepare(w: Dictionary) -> void:
	if w.has("craft_rng"): return
	var rng:=RandomNumberGenerator.new()
	rng.randomize()
	w.craft_rng=rng.randi_range(1,2147483646)
static func next(w: Dictionary) -> int:
	prepare(w)
	w.craft_rng=(int(w.craft_rng)*1664525+1013904223)%2147483647
	return int(w.craft_rng)
static func roll(w: Dictionary,bonus: int=0,base: Dictionary={"common":70,"fine":20,"great":10}) -> Dictionary:
	var chance:=next(w)%100
	var tier: String="great" if chance<int(base.great)+bonus else ("fine" if chance<int(base.great)+int(base.fine)+bonus else "common")
	var spread:=next(w)
	var attack: int=27+spread%3 if tier=="great" else (24+spread%3 if tier=="fine" else 20+spread%5)
	return {"tier":tier,"attack":attack}
static func valid(w: Dictionary) -> bool:
	var seed=w.get("craft_rng")
	return (seed is int or seed is float) and is_finite(float(seed)) and seed>=0 and seed<2147483647 and seed==floor(seed)

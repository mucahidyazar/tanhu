class_name CineScene
extends Node3D
## Sinema sahnelerinin tabanı (scenes/cine/*.tscn kökü; godot.md §3.6). CineHost segment başlarken sahneyi
## kurar ve setup(ctx) çağırır, segmentin olaylarını iletir; segment bitince ya da atlanınca restore()
## çağırıp sahneyi siler.
##   ctx: main (Main ya da null), world (segmentin dünyası: kamp, örneklenen dünya ya da null),
##        menu_camera, fade (UI/Fade), audio (CineAudio), host (CineHost), segment (çizelgenin segment kaydı)
## Olaylar: on_shot(name, ev) çekim olaylarıdır (kamera, AnimationPlayer); on_event(ev) öbür olayların
## hepsidir (konağın uyguladıkları da: şarkı, satır, perde; sahne istediğine tepki verir). ev'nin t'si
## mutlak, local_t segment içi saniyedir.
## Kural: sahne dokunduğu her şeyin (kamera, gök tekdüzenleri, sis, kişilerin pozu) önceki hâlini setup'ta
## alır, restore'da geri yazar: menüye dönüş karesi değişmez. seeking doğruyken (ileri sarma) ses çalınmaz,
## yalnız durum kurulur; olayın üstünden geçen süre elapsed(ev)'dir (AnimationPlayer'ı oraya sarmak için).
## is_ready() false döndükçe konak segmentin olaylarını bekletir (dünyası ya da ağır kurulumu bitmemiş sahne).

## Konak ileri sarıyor mu? Konak her olaydan önce yazar.
var seeking := false
var ctx: Dictionary = {}


## Segment başlarken bir kez (sahne ağaca eklendikten sonra) çağrılır.
func setup(p_ctx: Dictionary) -> void:
	ctx = p_ctx


func on_shot(_shot_name: String, _ev: Dictionary) -> void:
	pass


func on_event(_ev: Dictionary) -> void:
	pass


func is_ready() -> bool:
	return true


## Segment bitince ya da atlanınca bir kez çağrılır: sahnenin dokunduğu her şey eski hâline döner.
func restore() -> void:
	pass


## Sahneyi oynatan konak (yoksa null).
func host() -> CineHost:
	return ctx.get("host") as CineHost


## Sinema saati (saniye, dizinin başından).
func cine_time() -> float:
	var h := host()
	return h.time() if h else 0.0


## Olayın başından bu yana geçen sinema süresi (ileri sarmada sarmanın vardığı saate dek; kare taşmasında
## da > 0). AnimationPlayer'ı oraya sarmak için: player.play(name); player.seek(elapsed(ev), true).
func elapsed(ev: Dictionary) -> float:
	var h := host()
	return h.elapsed_since(ev) if h else 0.0

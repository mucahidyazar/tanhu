class_name CameraPreset
extends Resource
## Takip kamerasının ön ayarı (godot.md §5.7, K39; K98 kadrajıyla yeniden hesaplandı, act1.md §4): eğim, uzaklık, görüş, ileri pay ve
## karışım. FollowCamera.apply_preset() devreye alır, geçiş blend saniyede karışır; oyuncunun eğim payı (ayar ve oturum) ön ayarın
## üstüne eklenir, yalnız payı bekleten ön ayarlar (oda, sahne çekimleri) onu durdurur.
##
## Sayılar Godot tabanındandır (K98: 38°, 36°, 28 m; düz zeminde kuzeye 27,2 m, güneye 10,0 m, kahraman hizasında ±16,4 m):
##   walk     38°, 28 m (çocukta 22 m)                       Yürüyüş, varsayılan
##   ride     38°, yürüyüşün 6 m ötesi (34 m; çocukta 28 m)  Sürüş (atta; FollowCamera.auto_presets): kuzeye 32,6 m, güneye 12,2 m, ±19,9 m;
##                                                          dörtnalda hız genişlemesiyle (38,5°) kuzeye 36,9 m, güneye 12,9 m; kamanın
##                                                          dörtnaldaki arka sırası (sancağın atı 12,0 m geride) kadrajın %4 içindedir
##   crouch   en az 34 m (eğim uzaklıktan: 41°), geri pay 4,7 m   Çömelme: nöbetçinin 16 m'lik görüş çemberi %5 payla kadrajdadır
##   room     50°, oyuncunun uzaklığı, payı bekletir, kuzey   Oda (yurt, ahır içi): çatı kalkar, kamera içeri girmez (K98); açı kuzeye döner,
##                                                          çıkınca oyuncunun açısı geri gelir (K27); yakın duvarın gizlediği taban 28 m'de
##                                                          1,25 m (38°'de 2,0 m)
##   lookout  15°, 44 m, payı bekletir                       Bakış Noktası: K98'in ufuk istisnası (≥40 m)
##   tengri   13°, 70 m, payı bekletir                       Tengri, Yar Bakışı: K98'in ufuk istisnası
## Uzaklığın kipi: "start" ön ayarın başlangıç uzaklığıdır (oyuncunun tekerlek payı korunur, `/` oraya döner); "offset" de öyledir ama
## uzaklık yürüyüşün başlangıcına eklenir (yetişkinde 28, çocukta 22 m'nin ötesi); "at_least" oyuncunun
## uzaklığı daha küçükse ona çıkar, büyükse dokunulmaz; "keep" uzaklığa dokunmaz; "fixed" uzaklığı sınırların dışında da sabitler
## (tekerlek bekler).

## Kimlik (walk, ride, crouch, room, lookout, tengri).
@export var id := &"walk"
## Eğim (derece): "start" ve "offset" kipinde uzaklığın eğiminin tabanı, "keep" ve "fixed" kipinde sabit eğim; "at_least" yürüyüşün eğim
## eğrisini kullanır (çömelmede 34 m'de 41°).
@export var pitch_deg := 38.0
## Uzaklık (metre; kipine göre).
@export var distance := 28.0
@export_enum("start", "offset", "at_least", "keep", "fixed") var distance_mode := "start"
## Dikey görüş açısı (derece); 0 oyuncunun ayarıdır (GameSettings.camera_fov).
@export var fov := 0.0
## İleri pay (metre): artı bakılan nokta kameranın ileri yönünde (yerde) öne kayar, eksi kameraya doğru geri kayar.
@export var lead := 0.0
## Oyuncunun eğim payını (ayar ve oturum) ve açısını bekletir mi (oda ve sahne çekimleri; K27)? Çıkınca ikisi de geri gelir.
@export var holds_bias := false
## Payı bekletirken açı kuzeye döner mi (oda; K27)?
@export var faces_north := false
## Geçiş süresi (saniye).
@export var blend := 1.1


static func make(p_id: StringName, p_pitch: float, p_distance: float, p_mode: String, p_lead := 0.0, p_holds := false, p_fov := 0.0) -> CameraPreset:
	var p := CameraPreset.new()
	p.id = p_id
	p.pitch_deg = p_pitch
	p.distance = p_distance
	p.distance_mode = p_mode
	p.lead = p_lead
	p.holds_bias = p_holds
	p.fov = p_fov
	return p


## Yürüyüş (varsayılan): 38°, 28 m; çocukta (Çocukluk, Serbest Gez'in Çocuğu) 22 m.
static func walk(child := false) -> CameraPreset:
	return make(&"walk", FollowCamera.DEFAULT_PITCH_DEG, FollowCamera.CHILD_DISTANCE if child else FollowCamera.DEFAULT_DISTANCE, "start")


## Sürüş (atta): 38°, yürüyüşün başlangıcının 6 m ötesi: yetişkinde 34 m, çocukta 28 m (k98-recalc).
static func ride() -> CameraPreset:
	return make(&"ride", FollowCamera.DEFAULT_PITCH_DEG, 6.0, "offset")


## Çömelme: uzaklık en az 34 m (eğim uzaklıktan, 41°), bakılan nokta 4,7 m kameraya doğru (k98-recalc).
static func crouch() -> CameraPreset:
	return make(&"crouch", FollowCamera.DEFAULT_PITCH_DEG, 34.0, "at_least", -4.7)


## Oda (yurt, ahır içi): 50°, oyuncunun uzaklığı; payı bekletir, çıkınca geri gelir (k98-recalc).
static func room() -> CameraPreset:
	var p := make(&"room", 50.0, 0.0, "keep", 0.0, true)
	p.faces_north = true
	return p


## Bakış Noktası: 15°, 44 m; ufuk istisnası (K98).
static func lookout() -> CameraPreset:
	return make(&"lookout", 15.0, 44.0, "fixed", 0.0, true)


## Tengri, Yar Bakışı: 13°, 70 m; ufuk istisnası (K98).
static func tengri() -> CameraPreset:
	return make(&"tengri", 13.0, 70.0, "fixed", 0.0, true)


## Bütün ön ayarlar (tablo ve sınama için).
static func all() -> Array[CameraPreset]:
	var out: Array[CameraPreset] = [walk(), ride(), crouch(), room(), lookout(), tengri()]
	return out

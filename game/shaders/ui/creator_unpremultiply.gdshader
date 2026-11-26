// Saydam bir SubViewport'a pişirilmiş dokuyu doğru renklerle çizer (CreatorBakedRect kullanır).
//
// Godot saydam bir görüntü alanına çizerken rengi alfa ile çarpar (premultiplied alpha). Burada bu
// çarpım geri alınır; böylece kâğıt gölgesi gibi yarı saydam kenarlar koyu bir hale bırakmaz ve
// düğümün modulate değeri (ör. açılıştaki solma animasyonu) her zamanki gibi çalışır.
shader_type canvas_item;

varying vec4 v_modulate;

void vertex() {
	// Köşe rengi burada CanvasItem'ın modulate ve self_modulate değerleriyle çarpılmış haldedir.
	v_modulate = COLOR;
}

void fragment() {
	vec4 baked = texture(TEXTURE, UV);
	COLOR = vec4(baked.rgb / max(baked.a, 0.0001), baked.a) * v_modulate;
}

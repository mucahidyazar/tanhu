// Desenli keçe halı / kilim (kamp referansı menu_camp.png'deki gibi koyu kırmızı-kahve, ince desenli): koyu dış
// kenar, ince bordür bandında küçük basamaklı elmaslar, iç alanda enine şeritler halinde küçük elmas dizileri,
// ortada soluk, katmanlı bir madalyon; kısa kenarlarda püsküller. Desenler zeminden yalnızca biraz açık/koyudur
// (referansta halı uzaktan koyu bir leke, yakından ince desenli görünür).
// Boyalı görünüm: dokuma izi, hafif düzensiz (elle çizilmiş) çizgiler, aşınmış açık lekeler ve fırça gürültüsü.
//
// UV 0..1. "size" halının gövdesinin metre cinsinden ölçüsüdür; mesh kısa kenarlarda "fringe" kadar uzatılır
// (püsküller bu bölgeye çizilir). Işık ortak "After the Wind" cel modelidir.
shader_type spatial;
render_mode cull_back, specular_disabled;

#include "res://shaders/include/rug_body.gdshaderinc"

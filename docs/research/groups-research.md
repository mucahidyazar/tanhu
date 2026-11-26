# Modu-era map groups: research for the game architect

No project files were changed. Line numbers refer to `/Users/mucahidyazar/Code/tests/tanhu-programatic-test/src/map/geography.js`.

## 0. Evidence and conventions

**Abbreviations:** SJ = Shiji, HS = Hanshu, HHS = Hou Hanshu, SGZ = Sanguozhi, WL = Weilüe (in the SGZ 30 notes).

**Read directly:**
- Primary text on Chinese Wikisource:
  - SJ 7, 81, 93, 99, 110, 111, 113, 114, 115, 116, 123, 129
  - HS 6, 28, 54, 61, 94A/B, 96A/B
  - HHS 87, 89, 90
  - SGZ 30 with WL, and Suishu 83
- Benjamin, "The Yuezhi Migration and Sogdia" (2003).
- Liu F. et al., Radiocarbon 61(4) 2019, and Frontiers in Earth Science 2021.
- Pulleyblank 1999, abstract only.
- A review of Byington, and Hill's Weilüe translation (text only, not his notes).
- Xinhua 2006 interviews with Wang Jianxin, plus Sixth Tone, chinawriter 2018, China News 14 Jul 2026 and Astana Times Oct 2026.
- An unsigned Turkish article (turkcetarih.com) that discusses De Groot and Maenchen-Helfen.
- English, Chinese and Turkish Wikipedia pages.

**Not seen, so not cited as read:**
- The translated text of Watson, Di Cosmo, Yü, Barfield, Beckwith, Psarras and Hulsewé.
- I saw these only as bibliographic records, reviews, or citations inside Wikipedia. Any such claim is marked "via Wikipedia".
- ctext.org refused automated access and the Pulleyblank PDF and a Heidelberg study returned bot blocks. I did not work around those.

**Reliability caveats:**
- Chinese quotes passed through a fetch tool, and the HS 96 pages carry an "unproofed" banner. Spot-check any line before printing it in-game.
- The Transoxiana page was read with certificate checks off, because the site's TLS certificate is mismatched.

**Marks:**
- `*` on a Turkish string = my proposal, with no established form found.
- `≈` = my approximation.
- `[placeholder]` = position is representational only.
- `(from memory)` = not re-verified here.

## 1. Records

### Xiongnu and its lineages

**xiongnu** · tr "Hun Tanhuluğu" · en "Xiongnu" · zh 匈奴
- **Kind:** "Yay Çekenler Ülkesi"* / "bow-drawing state" (引弓之國, Emperor Wen's letter, SJ 110). Self-style in the letter: 天所立匈奴大單于.
- **Location, Acts 1–2:** `[[104,41],[108,41.2],[112,41.6],[112.8,44],[112,47.5],[110,49.2],[105,49.6],[100.5,48],[99.5,45],[100.5,43]]`. After the Donghu fall, use the line 206 polygon.
- **SJ 110 meridians:** the court faces Dai and Yunzhong (≈111.2–114.5E). The left wing lies east of Shanggu (≈115.5E, from memory). The right wing lies west of Shang commandery (≈109.5E, from memory).
- **Show:** c. 215–174.
- **In Modu's life:** Meng Tian drives Touman north (215). Modu's coup comes next. 控弦之士三十餘萬 (SJ 110).
- **Reveal:** Act 1, the home he remembers as a hostage.

**Lineages: do not put these on the map.** Sources give no territory for them in Modu's time. Show them as text in a Xiongnu panel. Remove the pins at lines 381–385.

| id | tr | en / zh | kind | Evidence | Reveal |
|---|---|---|---|---|---|
| luandi | "Luandi" | Luandi 攣鞮氏 (HHS 89 虛連題 Xulianti) | "Tanhu soyu"* / Chanyu's lineage | HS 94A 單于姓攣鞮氏. Not in the SJ 110 passages I read. | Act 2, title |
| huyan | "Huyan" | Huyan 呼衍氏 | "Hatun veren soy"* / consort-giving lineage | SJ 110 貴種. HHS 89 常與單于婚姻, 呼衍氏為左 | Act 2, the beys |
| lan | "Lan" | Lan 蘭氏 | same | SJ 110. HHS 89 右 | Act 2 |
| xubu | "Xubu" | Xubu 須卜氏 | "Sonradan yükselen soy"* / later noble lineage | SJ 110 其後有須卜氏 | Act 4 or later |
| qiulin | "Qiulin" | Qiulin 丘林氏 | Eastern Han noble surname | HHS 89 only, not SJ or HS | Never in Modu's lifetime |

The HHS 89 left/right split and the role 主斷獄聽訟 describe the Southern Xiongnu era. The role covers all three named lineages, not Xubu alone.

### East

**qidi** (needed by Act 3) · tr "Issız Toprak"* · en "the abandoned land" · zh 棄地, with 甌脫 watch-posts on both edges
- **Location:** `[[112.8,42],[118,42.3],[118,45],[118.8,48],[112,47.5],[112.8,44]]` [placeholder].
- **Width:** 千餘里 (SJ 110). 1000 li ≈ 416 km ≈ 5.2° of longitude at 44N.
- **Reveal:** Act 3, third demand.

**donghu** · tr "Tung-hu (Doğu Hu)" · en "Donghu (Eastern Hu)" · zh 東胡
- **Kind:** "Hu krallığı"* / Hu kingdom (東胡王).
- **Location:** `[[118,42.3],[120,42.7],[123,42.4],[124,43.8],[123,46.5],[120.8,48.5],[118.8,48],[118,45]]`. The north limit is unknown. The Upper Xiajiadian link is uncertain, and Jinggouzi only "may have been associated" (Wikipedia).
- **Show:** to c. 206.
- **Before Modu:** Qin Kai pushed them back 千餘里 (SJ 110). Li Mu 破東胡 (SJ 81).
- **In Modu's life:** horse, consort, land; 大破滅東胡王，而虜其民人及畜產 (SJ 110).
- **Aftermath:** Lu Wan is titled 東胡盧王 in 195 (SJ 93).
- **Year:** SJ gives none. "By 208" is Di Cosmo via Wikipedia.
- **Reveal:** Act 2 (東胡彊而月氏盛). The envoy opens Act 3.

**donghu_remnant** · tr "Tung-hu Kalıntıları"* · en "Donghu remnants" · zh 東胡餘類
- **Kind:** "Dağa çekilen kalıntı"* / mountain refugees.
- **Location:** pins "Wuhuan Dağı" ≈[119.7,44.6] and "Xianbei Dağı" ≈[120.9,45.3]. Both are disputed: CASS (seen in a search excerpt only) suggests Wuliao Shan, northwest of Ar Horqin. A Horqin Right Middle identification competes for Xianbei.
- **Show:** 206–174, as mountain names only.
- **Source:** HHS 90, 餘類保烏桓山 and 歲輸牛馬羊皮.
- **Reveal:** end of Act 3.

**huimo** (missing today) · tr "Huimo (Yemaek)"* · en "Huimo (Yemaek)" · zh 穢貉
- **Kind:** "Beylikler"* / chiefdoms (HS 6 東夷薉君南閭, 128 BC).
- **Location:** blob [127,42.8,2.6,1.6] [placeholder].
- **Show:** whole game.
- **Source:** SJ 110, the left wing 東接穢貉、朝鮮.
- **Reveal:** end of Act 3.

**chaoxian** · tr "Çoson"* · en "Joseon (Chaoxian)" · zh 朝鮮
- **Kind:** "Krallık" / kingdom.
- **Location:** polygon at line 307.
- **Show:** to 194.
- **Source:** WL: Yan took 二千餘里. 否死，其子准立.
- **Naming:** "Gojoseon" is a retrospective label. Wikipedia says historians add "Go". One account credits Iryeon with applying it.
- **Reveal:** end of Act 3.

**wiman** · tr "Viman Çoson" · en "Wiman Joseon" · zh 朝鮮王滿
- **Kind:** "Dış vasal"* / outer vassal (外臣, SJ 115).
- **Location:** `[[124.3,40],[127.3,41.6],[129.2,41],[128.6,38],[127,37.2],[124.9,38]]`. Capital 王險 ≈[125.75,39.02].
- **Show:** 194–174.
- **Source:** Lu Wan's revolt, 滿亡命，聚黨千餘人; 真番、臨屯皆來服屬，方數千里 (SJ 115).
- **Reveal:** Act 6.

**zhenfan** 真番 and **lintun** 臨屯 · tr "Zhenfan"*, "Lintun"* · en same
- **Kind:** "Bağlı ülke"* / tributary.
- **Location:** blobs ≈[126.3,38.2,1,0.7] and ≈[128.2,38.6,0.7,1] [placeholder].
- **Show:** 194–174.
- **Reveal:** Act 6.

**buyeo** · tr "Puyo" · en "Buyeo (Puyŏ)" · zh 夫餘
- **Kind:** "Ülke" / state.
- **Location:** blob [126,44.6,2,1.6] on the Songhua.
- **Justification:** weak. SJ 129 names it c. 100 BC. The earliest secure mention is 2nd c. BC. Byington argues for an earlier formation, with the Xituanshan precursor lasting to the 3rd c. BC (via the review). No contact with Modu is recorded.
- **Show:** 176–174 as faint ambient only.
- **Reveal:** Act 6 or epilogue.

**jin** · tr "Cin" · en "Jin" · zh 辰
- **Kind:** "Ülke".
- **Location:** blob [127.6,36,1.2,1.2].
- **Show:** 194–174, ambient.
- **Evidence:** retrospective, SGZ 30 辰韓者，古之辰國也. Wikisource SJ 115 reads 真番旁眾國, not 辰國.
- **Reveal:** Act 6.

### West: Yuezhi and the 176 BC letter

**yuezhi** · tr "Yüeçi" · en "Yuezhi" · zh 月氏
- **Kind:** "Göçer ülke"* / moving state (行國, SJ 123, HS 96A). Ruler is 月氏王.
- **Location:**
  - Acts 1–3: polygon at line 233.
  - Acts 4–5: `[[92.5,41.5],[96,42],[99.8,40.4],[101.2,38.7],[100.4,37.5],[99,37.2],[95.5,38.5],[92.5,39]]`.
  - Act 6: `[[92.5,41.2],[97.5,41],[98.6,39.6],[96.5,38.6],[92.5,39]]`. This shrink is my inference from Benjamin's last defeat "near Dunhuang in c.162".
- **Show:** whole game. Never at Ili before 174.
- **In Modu's life:**
  - 月氏盛.
  - Touman 急擊月氏, and the hostage escape (SJ 110).
  - 西擊走月氏 (SJ 110, undated; c. 206–203; "203" is Di Cosmo via Wikipedia).
  - 176: Right Worthy King, 夷滅月氏，盡斬殺降下之 (SJ 110).
- **The 176 claim is hyperbole:** SJ 123 and HS 96A have Laoshang kill the king later. HHS 87 alone says 月氏王爲匈奴冒頓所殺.
- **Flight:** Benjamin puts departure at c. 162, Ili until 132. Wikipedia's Yuezhi timeline gives 165.
- **Strength:** 控弦者可一二十萬 (SJ 123, as of c. 128).
- **Reveal:** Act 1.

**wusun** · tr "Vusun" (also "Usun", "Wusun") · en "Wusun" · zh 烏孫
- **Kind:** "Küçük göçer ülke"* / small moving state (小國 HS 61; 行國 SJ 123).
- **Location:** blob [93.4,42.6,2.6,1.5] follows SJ 123 匈奴西邊小國. HS 61 instead says 祁連、焞煌閒, which would be ≈[95.5,40,2,1.2]. The sources conflict.
- **Who killed Kunmo's father:** SJ 匈奴攻殺其父. HS 大月氏攻殺難兜靡 (173 per Benjamin).
- **Show:** 176–174.
- **Reveal:** Act 6 letter, with an optional rumour in Act 1 on the HS reading. Ili comes only from c. 133–132.

**hujie** · tr "Hucie" · en "Hujie" · zh 呼揭 (烏揭, 呼偈)
- **Kind:** "Küçük ülke"* / small state (服虔: 呼偈，小國名，在匈奴北, via zh-Wikipedia).
- **Location:** blob [86.8,47,3.2,1.6]. zh-Wikipedia gives Tacheng, upper Irtysh, Altai and east Kazakhstan. HS 94B has 西方呼揭王.
- **Show:** 176–174.
- **Reveal:** Act 6.

**loulan** · tr "Loulan" · en "Loulan" · zh 樓蘭
- **Kind:** "Surlu ülke"* / walled state (邑有城郭，臨鹽澤, SJ 123).
- **Location:** pin [89.9,40.5].
- **Show:** 176–174. The name Shanshan is later (HS 96A).
- **Reveal:** Act 6.

**xiyu26** · tr "Yirmi Altı Ülke"* · en "the Twenty-Six States" · zh 其旁二十六國
- **Kind:** "Surlu ülkeler"* / walled states.
- **Location:** blob [83.2,39.6,7,2.6].
- **Show:** 176–174.
- **Exact text:** 定樓蘭、烏孫、呼揭及其旁二十六國，皆以爲匈奴.
- **Flags:**
  - The letter names none of the 26, so do not present any list as "the 26".
  - The grammar reads as 26 besides the three (my reading).
  - HS 96A's 本三十六國 is the count from Emperor Wu's time.
- **Reveal:** Act 6.

**Oasis pins (rename only, all Act 6).** Use period names. Attestation is later than 176, so tag them "adı sonradan biliniyor". Household figures are Han-era and useful only for relative rank.

| Line | Now | Show as | zh | Households | Attested in |
|---|---|---|---|---|---|
| 413 | Qiemo | Qiemo | 且末 | 230 | HS 96A |
| 414 | Hotan | Yutian | 于闐 | 3,300 | SJ 123 |
| 415 | Yarkent | Suoju | 莎車 | 2,339 | HS 96A |
| 416 | Kaşgar | Shule | 疏勒 | 1,510 | HS 96A |
| 417 | Aksu | Gumo | 姑墨 | 2,200 | HS 96B |
| 418 | Kuça | Qiuci | 龜茲 | 6,970 | HS 96B |
| 419 | Karaşar | Yanqi | 焉耆 | 4,000 | HS 96B |
| 420 | Turfan | Gushi | 姑師 | 700 + 595 as 車師 | SJ 123, HS 96B |

### South-west of the Xiongnu

**qiang** · tr "Çiang" · en "Qiang" · zh 羌
- **Kind:** "Çoban soyları"* / pastoral kin-branches (種, HHS 87).
- **Location:** blob [100.5,35.4,5,2.4] (≈ Hehuang and the 賜支 bend).
- **Show:** whole game.
- **In Modu's life:** 走月氏，威震百蠻，臣服諸羌 (HHS 87). Right-wing neighbour (SJ 110).
- **Reveal:** Act 4.

**di** (missing today) · tr "Di"* · en "Di" · zh 氐
- **Kind:** "Beylikler"* / chiefdoms (君長, 皆氐類也, SJ 116).
- **Location:** blob [104.8,33.4,1.6,1] ≈ Baima.
- **Show:** whole game.
- **Source:** named only as a neighbour, SJ 110 接月氏、氐、羌. HS 94A has 接氐、羌, dropping Yuezhi.
- **Warning:** 氐 is not 狄.
- **Reveal:** Act 4.

### Ordos

**loufan** · tr "Loufan" · en "Loufan" · zh 樓煩
- **Kind:** "Henan krallığı"* / Henan king's realm (河南王).
- **Location:** blob [110.6,39.3,1.4,1.2].
- **Show:** 209–174. Do not end at era 209.
- **In Modu's life:**
  - Zhao 北破林胡、樓煩 earlier (SJ 110).
  - 南并樓煩、白羊河南王 (SJ 110).
  - Still in place c. 198 (SJ 99).
  - Expelled only in 127 (SJ 110, 111).
- **Colour:** SJ 7 has archers called 樓煩 serving Han.
- **Reveal:** Act 4.

**baiyang** · tr "Baiyang (Ak Koyun)" · en "Baiyang" · zh 白羊
- **Kind:** same as Loufan.
- **Location:** blob [107.9,38.7,1.6,1.4].
- **Check:** SJ 99 says 去長安近者七百里，輕騎一日一夜可以至秦中. 700 li ≈ 291 km, which is ≈36.9N, so the Henan kings' reach must run well south of the current blob.
- **Show:** 209–174.
- **Reveal:** Act 4.

### The five northern peoples

The text is one sentence: 後北服渾庾、屈射、丁零、鬲昆、薪犁之國 (SJ 110, undated). WL adds 匈奴北有渾窳國，有屈射國，有丁令國，有隔昆國，有新梨國. Wikisource HS 94A prints a garbled last name (龍新赚), so use SJ or WL for it.

- **Kind:** "Kuzey ülkesi"* / northern state (國).
- **Show:** c. 203–174.
- **Reveal:** Act 5 opening.
- **Certainty:** Wikipedia's Dingling page calls the locations of Hunyu, Qushe and Xinli unknown. Tag all three [placeholder].

| id | tr | en / zh | Blob | Basis |
|---|---|---|---|---|
| hunyu | "Hun-yü" | Hunyu 渾庾 / 渾窳 | [100.5,50,2.4,1.1] | Turkish article: Selenga valley or slightly west. It doubts De Groot's Orkhon idea. |
| qushe | "Çüşe" | Qushe 屈射 | [93,49.2,2.4,1.1] | Same article, on my reading, places them between Altai and Tannu-Ola. Kipchak link disputed (Golden, via zh-Wikipedia). |
| dingling | "Ting-ling (Dingling)" | Dingling 丁零 / 丁令 | [105.5,51,5,1.7] | WL 北海之南. HS 54 丁令盜武牛羊 at 北海. Selenga basin per the Turkish article. |
| gekun | "Ko-k'un (Gekun)" | Gekun 鬲昆 / 隔昆 / 堅昆 | [93,52.4,3,1.5] | Upper Yenisei. HS 94B 東去單于庭七千里 is 1st c. BC and conflicts. |
| xinli | "Hsin-li (Sinli)" | Xinli 薪犁 / 新梨 | [88,50.9,2.2,1.1] | South Siberia per Pulleyblank's abstract, nothing firmer. |

### China and the south

**qin** · tr "Ç'in İmparatorluğu" · en "Qin Empire" · zh 秦
- **Kind:** "İmparatorluk".
- **Location:** polygon at line 222.
- **Show:** to 207–206.
- **Source:** Meng Tian's expulsion and death (SJ 110).
- **Reveal:** Act 1.

**chu_han** (missing) · tr "Batı Çu ve Han savaşı"* · en "Western Chu vs Han" · zh 項羽 / 漢
- **Kind:** "İç savaş"*.
- **Location:** no borders.
- **Show:** 206–202.
- **Source:** 是時漢兵與項羽相距 (SJ 110).
- **Reveal:** Act 4.

**han** · tr "Han Hanedanı" · en "Han" · zh 漢
- **Kind:** "İmparatorluk" (冠帶之室, SJ 110).
- **Location:** polygon at line 227, minus Minyue. North line at 朝那 ≈[106.6,35.9] and 膚施 ≈[109.8,38] (from memory).
- **Show:** 202–174.
- **In Modu's life:** Mayi and 韓王信 (201), Baideng (200), heqin (198), SJ 93, 99, 110.
- **Reveal:** name in Act 4, full polygon in Act 5.

**nanyue** · tr "Nanyue" · en "Nanyue" · zh 南越
- **Kind:** "Krallık".
- **Location:** polygon at line 327.
- **Show:** c. 204–174.
- **Source (SJ 113):** 秦已破滅…自立為南越武王; 漢十一年 Lu Jia; 自尊號為南越武帝; 閩越、西甌、駱，役屬焉.
- **Reveal:** Act 6.

**minyue** (missing) · tr "Minyue"* · en "Minyue" · zh 閩越
- **Kind:** "Krallık".
- **Location:** `[[116.6,24.6],[118.6,24.6],[120.2,26.6],[120.6,27.4],[118.4,28],[116.6,26.6]]`. Capital 東冶 ≈[119.3,26.1].
- **Show:** 202–174.
- **Source:** 漢五年，復立無諸為閩越王 (SJ 114).
- **Reveal:** Act 6.

**dongou** (missing) · tr "Dong'ou"* · en "Dong'ou (Donghai)" · zh 東甌
- **Kind:** "Krallık".
- **Location:** blob ≈[120.6,28.4,0.9,0.7].
- **Show:** 192–174.
- **Source:** 孝惠三年 (SJ 114).
- **Reveal:** Act 6.

**dian** · tr "Dian" · en "Dian" · zh 滇
- **Kind:** "Krallık" (以其眾王滇, SJ 116).
- **Location:** blob at line 331.
- **Show:** ambient.
- **Reveal:** epilogue.

**yelang** (missing, optional) · tr "Yelang"* · en "Yelang" · zh 夜郎
- **Kind:** "Beylikler" (君長, SJ 116).
- **Location:** blob ≈[105.5,26.5,2,1.3].
- **Show:** ambient.
- **Reveal:** epilogue.

### Outer ring

These have no recorded contact with Modu. Keep them out of story reveals and unlock them only in the epilogue, through the Yuezhi flight.

| id | tr | en / zh | Kind | Location | Note |
|---|---|---|---|---|---|
| sai | "Sakalar" | Saka 塞 (塞王, 塞種) | "Sai krallığı"* | blob at line 249 | Show through 174. HS 61 月氏…西擊塞王 falls after Modu's blow. |
| dayuan | "Davan" (sub "Fergana") | Dayuan 大宛 | "Surlu krallık"* (有城郭屋室) | polygon at line 266 | First known c. 128 via SJ 123. |
| kangju | "Kangju" | Kangju 康居 | "Göçer ülke" (行國) | blob at line 261 | First known c. 128. Wikipedia infers it appeared later. Benjamin's Kangju = Sogdia is disputed. Optional. |
| bactria | "Greko-Baktriya" | Greco-Bactria (later Chinese 大夏) | "Yunan krallığı"* | polygon at line 271 | Antiochus besieged Bactra c. 208–206. Demetrius c. 200–180. |
| sogdiana | "Soğdiana"* | Sogdiana | "Yunan satraplığı"* | ≈`[[64,39.4],[68.6,39.4],[68.2,41],[64.5,41]]` | Greek hold uncertain. |
| parthia | "Part Krallığı" | Parthia, later 安息 | "Arsak krallığı"* | `[[58,36.2],[60,36.4],[60.6,37.6],[58.6,38.6],[58,38.6]]`, pin Nisa [58.195,37.967] | Barely inside the window. |
| maurya, shunga | as now | Maurya, Shunga | "İmparatorluk", "Krallık" | lines 336, 341 | Valid, irrelevant to Modu. Low rank. |

## 2. Must NOT be shown in 234–174 BC

- **Türk, Göktürk:** 6th c. AD (Zhoushu 50, in the local research file).
- **Kırgız as a label (line 350):** use Gekun.
- **Tiele, Gaoche, Uyghur, Oghuz:** later names.
- **Xianbei and Wuhuan as polities:** HHS 90 derives the names from refuge mountains after the fall. Xianbei first act in AD 45 and 49. Wuhuan appear as a Han frontier group after Huo Qubing.
- **Yilou:** only in SGZ 30. Sushen is a vaguer older name with no link to this story. Delete line 301.
- **Samhan:** SGZ 30.
- **Goguryeo, Okjeo, Silla, Baekje** (from memory).
- **Wa and Yayoi (line 167):** Wa appears in SGZ 30. Yayoi is an archaeological term.
- **Da Yuezhi, Xiao Yuezhi, Kushan:** all after Modu.
- **Xiutu and Hunye kings of Hexi** (121 BC era), and **Rizhu King with the 僮僕都尉** (HS 96A, later).
- **Han Hexi commanderies and the Zhaowu county name:** after 121.
- **Shanshan and the "36 states":** later.
- **Linhu, Danlan:** already beaten before Modu (SJ 81). **Yiqu, Shanrong:** pre-period (from memory).
- **Seleucids:** no stable presence inside the window. Antiochus passed through in 209–205 and left.
- **Rouran, Tuyuhun, Tibet:** later (from memory).
- **Ötüken (line 391, region at line 172):** a Turkic-era sacred name (from memory).
- **Archaeological cultures as polity labels:** Shajing, Shanma, Pazyryk, Tagar, Upper Xiajiadian.
- **Tocharian as a label:** a modern language name. The Yuezhi link is argued by Pulleyblank and contested by Wei et al.
- **Generic words:** "Kabile", "Klan", "kabileleri".

## 3. geography.js errata

- **Line 3:** the comment uses "kabile ve klan". Drop it.
- **Lines 17–22:** three eras cannot carry six acts. Era 209 merges the hostage, the coup and the Donghu war, and Qin is drawn through Qin's fall. Proposed ids and labels:
  - `210` "MÖ 210 dolayı"
  - `209` "MÖ 209"
  - `207` "MÖ 208–206"
  - `204` "MÖ 206–203"
  - `200` "MÖ 201–198"
  - `176` "MÖ 177–174"
  
  Only Baideng, heqin and 177–174 are dated in the sources. The rest are inferred.
- **Lines 167, 172, 187, 188:** remove Wa/Yayoi, Ötüken, Kore and Mançurya as period labels.
- **Lines 201 and 286:** the Xiongnu and Donghu polygons touch. SJ 110 requires the 千餘里 gap. Use the polygons above.
- **Line 211:** the `[88,47],[92,44]` corner swallows Hujie before 176. Replace it with `[88,49.5],[93,47],[94.5,44]`.
- **Line 227:** the Han polygon covers Minyue, and also the Di country that SJ 116 places outside Ba-Shu.
- **Line 234:** "yıllar sonra bu toprakları fethetti" is too simple. Say routed c. 204, broken 176.
- **Lines 236–239:** `yuezhi174` at Ili is premature. Suggested note: "MÖ 176'da Sağ Bilge Kral Yüeçileri ezdi; mektup 'yok ettim' der, ama Yüeçi kralı Laoshang dönemine kadar yaşar. Asıl göç Mete'den sonradır."
- **Lines 241–242:** eras should be 176 onward. The note says Qilian–Dunhuang while the blob sits on the SJ reading. State both.
- **Line 245:** eras should be 176 onward.
- **Line 249:** add era 174.
- **Line 253:** rename to "Çiang" and move the blob centre.
- **Line 258:** "otuz altı" conflicts with the letter. Suggested note: "Mete'nin MÖ 176 mektubu Loulan, Vusun, Hucie'yi ve 'çevrelerindeki yirmi altı ülkeyi' anar, adlarını vermez."
- **Lines 261, 265, 280:** first attested c. 128. Remove Yancai or hide it, and do not label it "Aorslar" or "Sarmat" (not in SJ 123).
- **Line 276:** the Parthia polygon is too large.
- **Lines 289–296:** replace with `donghu_remnant`.
- **Line 298:** eras ALL overclaims Buyeo.
- **Lines 306, 316:** rename "Koçoson" to "Çoson".
- **Line 321:** drop sub "Samhan".
- **Line 331:** kind should not be "Kabile", since the note says "krallık".
- **Line 346:** the Dingling blob at 54.3N sits north of Baikal's south end, against WL 北海之南.
- **Line 350:** drop sub "Kırgız ataları".
- **Line 358:** no evidence supports [112.6,52.8].
- **Lines 346–363:** eras ALL should begin at Act 5.
- **Lines 367, 371:** eras `['209']` are wrong. They last until 127.
- **Line 378:** "Vuhuan ve Kore sınırına" should be 穢貉、朝鮮, i.e. "Huimo ve Çoson".
- **Line 380:** [110.4,43.6] is west of Yunzhong. Use ≈[112.8,43.5].
- **Lines 381–385:** remove the pins. Line 384 assigns the judicial role to Xubu alone. Line 385 is HHS only.
- **Line 390:** the 2017–2020 Arkhangai site is at 48°06′11″N 102°33′38″E. Its identification rests on press reports of tile text, and Wikipedia flags that claim as failing verification. Keep "tartışmalıdır".
- **Line 392:** Dailin has no known location. Remove the pin or mark it as unknown. Commentators may read 蹛 as a rite. I could not verify that gloss.
- **Line 421:** "Dunhuang" is a later commandery name. Lin Meicun (via Wikipedia) reads SJ's form differently.
- **Line 424:** "Ay Hanum" is a modern name (from memory).
- **Lines 432–434:** "MÖ 208", "205" and "203" are not in the sources. Tag them "dolayı".
- **Line 439:** "Jizhu (Laoshi)" is an error. Write "Jizhu (Laoshang)". 老上 per SJ 110.

**Naming inconsistency to settle:**
- geography.js has Mete, Teoman, Tunghu and Çilyan.
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/story/arastirma_cin_kaynaklari.md` has Motun, Tuman, Doğu Hu and Kilyen.

## 4. Reveal order

- **Act 1:** Xiongnu, Yuezhi, Qin.
- **Act 2:** Donghu by repute, Luandi, Huyan, Lan.
- **Act 3:** qidi, donghu fall, then donghu_remnant, Huimo, Joseon.
- **Act 4:** Chu–Han, Han (name), Loufan, Baiyang, Qiang, Di, Xubu.
- **Act 5:** Hunyu, Qushe, Dingling, Gekun, Xinli, then Han in full with 韓王信.
- **Act 6:** Loulan, Wusun, Hujie, Twenty-Six States and oasis pins, Nanyue, Minyue, Dong'ou, Wiman, Zhenfan, Lintun, faint Buyeo and Jin, Lu Wan's title.
- **Epilogue:** Yuezhi flight arrow, Saka, Dayuan, Kangju, Bactria, Sogdiana, Parthia, Dian, Yelang.

## 5. Tanhu Act 1 location

**Text anchors:**
- SJ 123 始月氏居敦煌、祁連閒.
- HHS 87 舊在张掖、酒泉地. This is the only text naming Zhangye and Jiuquan.
- Suishu 83 舊居祁連山北昭武城. A later tradition. HS 28 lists 昭武 under Zhangye. A local-history article places it near Yanuan in Linze, with the old city lost to the river.
- SJ 111 踰居延，遂過小月氏，攻祁連山. This shows the Juyan-to-Qilian route in 121 BC.

**Winter-camp logic:**
- Wang Jianxin: 冬季則選擇一些山嶺東南側或山脈深處有水源的較平緩的山谷地帶作為冬營地，並經年使用.
- Modern Sunan Yugur herders: 冬春場一般分布在海拔2000～3000米, and 夏放高山秋放川，冬放低山春放滩.

**Recommended camp (my inference, not an attested site):** ≈[99.62,38.84], a Qilian-front valley at today's Hongwansi, Sunan. The elevation of roughly 2,300 m is from memory. The current pin at line 430, [99.4,38.9], is about 20 km away and can stay.

**Alternatives:**
- Zhaowu plain ≈[100.08,39.20], about 58 km away, as the king's low ground.
- Yanzhi Shan and Damaying (lon 101.17–101.67, lat 38.0–38.25, from one encyclopedia-style site), best as summer horse pasture.
- **About "Yanqi":** HS 94A writes this Hexi mountain 焉耆山 where SJ 111 has 焉支山. It is not the Tarim state of Yanqi.
- The East Tianshan reading (below) is a rival frame, not a Gansu option.

**Distance to the frontier.** No source draws a border c. 210. The Xiongnu–Yuezhi adjacency in SJ 110 describes the later wings. The practical gate is Juyan.

| From [99.62,38.84] to | Straight line | Game km |
|---|---|---|
| Juyan delta, Ejin [101.07,41.95] | 367 km (≈450 km along the Ruo Shui) | 2.80 |
| [101.2,42.75], modern border as a proxy for the first Xiongnu pasture | 455 km (≈540 km by river route) | 3.48 |
| Gurvan Saikhan foot [103.5,43.5] | 611 km | |
| Gaoque, Yin Shan [107,40.9] | 670 km | |
| `CAMP_LONLAT` [103.1,47.35] | 987 km | |
| Arkhangai "Longcheng" | 1,056 km | |
| Chanyu's court zone [112.8,43.5] | 1,217 km | |

**Riding time:**
- The period benchmark is SJ 99, 700 li (≈291 km) in a day and a night by light cavalry. That is rhetorical.
- At that pace Juyan takes about 1.5 days.
- One horse in winter takes about 5–7 days (my estimate).

**Other distances:** Dunhuang 449 km, Mazongshan town 396 km, Sanjiaocheng ≈234 km.

**What a plausible camp looked like.** No site is securely Yuezhi. Mallory and Mair (via Wikipedia) and Wang both report none between Dunhuang and Qilian, so build from these models.

**Sanjiaocheng (Shajing culture), the closest Hexi analogue:**
- Datum 102°17′54″E, 38°37′18″N, 1,431 m, in Shuangwan, Jinchuan. Wikipedia's 38.99N/103.32E does not match this.
- Piled-earth walls, 175×126 m (news) or 154×132 m (Liu 2019). Base 6–8 m, surviving up to 4 m, south gate 7.3 m, bowl-shaped interior.
- 1979–81 cleared 4 house sites, 14 storage pits, 4 sacrificial pits and 585 tombs, in four cemeteries 400 m–1.5 km away.
- Built c. 828 cal BC, with barley from 384–116 cal BC.
- Barley and broomcorn millet in all samples, sheep and cattle bones.
- Settlement "primarily composed of portable yurts" (Pu & Pang, via Liu 2019).
- Shaft-and-niche graves with animal skulls, tiger-and-deer plaques, turquoise, wool, some iron.
- Attribution is contested: Yuezhi (a museum director says most scholars), Wusun, Qiang-Rong or Beidi. Benjamin notes Zadneprovsky's niche-tomb link to Issyk Kul and Ferghana.

**Western Hexi (Shanma culture):**
- c. 1000–100 BC, herding "oriented toward mobile pastoralism": camels, horses, cattle, sheep, no pigs.
- Mazongshan's Jingbaoer jade mine: 5.4×1.4–1.85 km, pottery c. 400–100 BC, 21 house foundations, defences, tamarisk firewood, about 39 mm rain a year.
- No source I saw ties it to the Yuezhi. Guanzi's jade-trading Yúzhī (via Wikipedia) makes the idea plausible for story use only.

**East Tianshan (Wang's rival reading, Qilian = Tianshan):**
- Yuegongtai–Xiheigou [92.96456,43.56973]: 3 stone platforms, 120+ stone enclosures, largest ≈900 m² ("王帐"), 300+ unmounded stone tombs, 1,000+ rock images.
- Proposed summer court, with winter at Wulatai on the sunny south slope (no coordinates found).
- Dongheigou/Shirenzigou [93.24,43.53]: c. 410–190 BC, which Wang reads as later Xiongnu.
- It conflicts with HHS 87 and SJ 111, so use it for the Yuezhi's western range rather than the hostage camp.
- Wang's own team reassigned one Samarkand site to Kangju, so treat his labels as hypotheses.

**Pazyryk:** do not use as a Yuezhi identity. One abstract calls the link "completely groundless" and another "far from being proved". Griffin-deer motifs are fine as regional style (Shirenzigou, via Wikipedia).

**Set dressing that follows from this:**
- Felt tents inside and around a low earth bank, with storage pits for barley and millet.
- Horses, sheep, cattle and camels. Tamarisk fires. A grave ridge at a distance.
- Bronze animal plaques, wool and turquoise.
- The ruler is 月氏王. Yabgu appears only in Bactria.

## 6. Other uncertain points

- Modu's birth "c. 234" has no primary basis I could find. Wikipedia gives it without a footnote.
- All placements for Hunyu, Qushe, Xinli, Zhenfan and Lintun are placeholders.
- Turkish forms for Di, Huimo, Minyue, Dong'ou and Yelang are proposals.
- I could not verify the Xihe jiushi text of the "失我焉支山" song, only modern retellings.

Sources:
- [SJ 110](https://zh.wikisource.org/wiki/史記/卷110), [SJ 123](https://zh.wikisource.org/wiki/史記/卷123), [SJ 111](https://zh.wikisource.org/wiki/史記/卷111), [SJ 93](https://zh.wikisource.org/wiki/史記/卷093), [SJ 99](https://zh.wikisource.org/wiki/史記/卷099), [SJ 113](https://zh.wikisource.org/wiki/史記/卷113), [SJ 114](https://zh.wikisource.org/wiki/史記/卷114), [SJ 115](https://zh.wikisource.org/wiki/史記/卷115), [SJ 116](https://zh.wikisource.org/wiki/史記/卷116), [SJ 129](https://zh.wikisource.org/wiki/史記/卷129), [SJ 7](https://zh.wikisource.org/wiki/史記/卷007), [SJ 81](https://zh.wikisource.org/wiki/史記/卷081)
- [HS 94A](https://zh.wikisource.org/wiki/漢書/卷094上), [HS 94B](https://zh.wikisource.org/wiki/漢書/卷094下), [HS 96A](https://zh.wikisource.org/wiki/漢書/卷096上), [HS 96B](https://zh.wikisource.org/wiki/漢書/卷096下), [HS 61](https://zh.wikisource.org/wiki/漢書/卷061), [HS 54](https://zh.wikisource.org/wiki/漢書/卷054), [HS 28B](https://zh.wikisource.org/wiki/漢書/卷028下), [HS 6](https://zh.wikisource.org/wiki/漢書/卷006)
- [HHS 87](https://zh.wikisource.org/wiki/後漢書/卷87), [HHS 89](https://zh.wikisource.org/wiki/後漢書/卷89), [HHS 90](https://zh.wikisource.org/wiki/後漢書/卷90), [SGZ 30](https://zh.wikisource.org/wiki/三國志/卷30), [Suishu 83](https://zh.wikisource.org/wiki/隋書/卷83)
- [Benjamin 2003](http://www.transoxiana.org/Eran/Articles/benjamin.html), [Liu et al. 2019](https://www.cambridge.org/core/journals/radiocarbon/article/chronology-and-plant-utilization-from-the-earliest-walled-settlement-in-the-hexi-corridor-northwestern-china/E604E4E53B407D6A88F80F7A7AD592F6), [Liu et al. 2021](https://www.frontiersin.org/journals/earth-science/articles/10.3389/feart.2021.636534/full), [Pulleyblank 1999 abstract](https://hrcak.srce.hr/en/109420), [Byington review](https://ijkh.khistory.org/journal/view.php?number=485), [Hill, Weilüe](https://depts.washington.edu/silkroad/texts/weilue/weilue.html)
- [Xinhua 2006 a](https://news.sina.com.cn/o/2006-11-02/095010388654s.shtml), [Xinhua 2006 b](https://news.sina.com.cn/o/2006-11-03/085210403205s.shtml), [Sixth Tone](https://www.sixthtone.com/news/1012683), [chinawriter 2018](https://www.chinawriter.com.cn/n1/2018/0718/c419392-30155138.html), [Astana Times 2026](https://astanatimes.com/2026/10/yuezhi-mystery-archaeologists-search-kazakhstan-for-lost-traces/), [Language Log](https://languagelog.ldc.upenn.edu/nll/?p=65252)
- [China News 2026](https://www.gs.chinanews.com.cn/news/2026/07-14/394433.shtml), [Sanjiaocheng datum](https://www.qinglite.cn/doc/515366500e7317609), [ifeng 2019](https://gs.ifeng.com/a/20191226/7983016_0.shtml), [The Paper](https://www.thepaper.cn/newsDetail_forward_24276529), [Zhaowu](https://www.zhangye.gov.cn/szb/dzdt/gjzy/202210/t20221025_927840.html), [Yugur pastures](https://www.dili360.com/article/p66d7ffab9553893.htm), [Yuegongtai](https://zh.wikipedia.org/zh-hans/岳公台—西黑沟遗址群), [Hujie](https://zh.wikipedia.org/zh-cn/烏揭), [Qushe](https://zh.wikipedia.org/zh-hans/屈射)
- [Pazyryk and the Yuezhi](https://www.e-anthropology.com/English/Catalog/Archaeology/STM_DWL_SzK8_3FkFkr8QGefR.aspx), [Turkish article](https://turkcetarih.com/tarihte-turkler/ilk-toles-boylari-ugur-ting-ling-ve-kao-cheler/), [Mete'nin Yüeçi Seferi](https://tr.wikipedia.org/wiki/Mete'nin_Y%C3%BCe%C3%A7i_Seferi), [Mete](https://tr.wikipedia.org/wiki/Mete), [Usunlar](https://tr.wikipedia.org/wiki/Vusunlar)
- Wikipedia: [Yuezhi](https://en.wikipedia.org/wiki/Yuezhi), [Wusun](https://en.wikipedia.org/wiki/Wusun), [Modu Chanyu](https://en.wikipedia.org/wiki/Modu_Chanyu), [Laoshang](https://en.wikipedia.org/wiki/Laoshang), [Dingling](https://en.wikipedia.org/wiki/Dingling), [Donghu](https://en.wikipedia.org/wiki/Donghu_people), [Jinggouzi](https://en.wikipedia.org/wiki/Jinggouzi_culture), [Shajing](https://en.wikipedia.org/wiki/Shajing_culture), [Shanma](https://en.wikipedia.org/wiki/Shanma_culture), [Shirenzigou](https://en.wikipedia.org/wiki/Shirenzigou_culture), [Dunhong](https://en.wikipedia.org/wiki/Dunhong), [Kangju](https://en.wikipedia.org/wiki/Kangju), [Sogdia](https://en.wikipedia.org/wiki/Sogdia), [Greco-Bactria](https://en.wikipedia.org/wiki/Greco-Bactrian_Kingdom), [Nisa](https://en.wikipedia.org/wiki/Nisa,_Turkmenistan), [Gojoseon](https://en.wikipedia.org/wiki/Gojoseon), [Yilou](https://en.wikipedia.org/wiki/Yilou), [Yelang](https://en.wikipedia.org/wiki/Yelang), [Longcheng](https://en.wikipedia.org/wiki/Longcheng,_Mongolia), [Science News](https://www.sciencenews.org/article/asia-xiongnu-nomadic-empire-expansion)
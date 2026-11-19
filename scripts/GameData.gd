class_name GameData
extends RefCounted

# ==============================================================================
#  ÇAYIR VADİSİ (SPIRIT MEADOW) V3 — MERKEZİ OYUN VERİLERİ
# ==============================================================================

const RARITY := [
	{"name": "Sıradan", "col": Color(0.88, 0.88, 0.90), "mult": 1.0},
	{"name": "Kaliteli", "col": Color(0.42, 0.96, 0.48), "mult": 1.32},
	{"name": "Nadir", "col": Color(0.36, 0.72, 1.0), "mult": 1.72},
	{"name": "Destansı", "col": Color(0.82, 0.44, 1.0), "mult": 2.25},
	{"name": "Efsanevi", "col": Color(1.0, 0.66, 0.18), "mult": 3.0},
]

# icon >= 1000 -> items_atlas.png (32 sütun) indeksi (icon - 1000)
const WEAPON_BASES := [
	{"name": "Paslı Kılıç", "icon": 1000, "ls": 0},
	{"name": "Bakır Kılıç", "icon": 1001, "ls": 0},
	{"name": "Çelik Kılıç", "icon": 1003, "ls": 0},
	{"name": "Altın Kılıç", "icon": 1004, "ls": 0},
	{"name": "Buz Kılıcı", "icon": 1005, "ls": 0},
	{"name": "Kristal Kılıç", "icon": 1008, "ls": 0},
	{"name": "Gölge Bıçağı", "icon": 1010, "ls": 2},
	{"name": "Güneş Kılıcı", "icon": 1011, "ls": 0},
	{"name": "Kan Dişi Kılıç", "icon": 1014, "ls": 6},
	{"name": "İblis Biçen Alev Kılıcı", "icon": 1016, "ls": 4},
	{"name": "Grog'un Savaş Baltası", "icon": 1068, "ls": 2},
	{"name": "Kadim Boşluk Tırpanı", "icon": 1014, "ls": 8},
	{"name": "Yıldız Işığı Büyü Asası", "icon": 1008, "ls": 6},
]

# skin: 0..4 hero görsel zırh katmanı
const ARMOR_BASES := [
	{"name": "Kumaş Tunik", "icon": 1221, "skin": 0},
	{"name": "Deri Yelek", "icon": 1220, "skin": 1},
	{"name": "Orman Avcısı Zırhı", "icon": 1227, "skin": 1},
	{"name": "Bakır Zırh", "icon": 1222, "skin": 2},
	{"name": "Zincir Zırh", "icon": 1223, "skin": 2},
	{"name": "Gölge Zırhı", "icon": 1226, "skin": 3},
	{"name": "Kan Şövalyesi Zırhı", "icon": 1234, "skin": 3},
	{"name": "Altın Şövalye Zırhı", "icon": 1224, "skin": 4},
	{"name": "İblis Lordu Zırhı", "icon": 1239, "skin": 4},
]

const SHIELD_BASES := [
	{"name": "Ahşap Kalkan", "icon": 1196},
	{"name": "Orman Kalkanı", "icon": 1199},
	{"name": "Demir Miğfer", "icon": 1203},
	{"name": "Şövalye Kalkanı", "icon": 1198},
	{"name": "Kanlı Kalkan", "icon": 1197},
	{"name": "İskelet Lordu Miğferi", "icon": 1207},
	{"name": "Altın Şövalye Miğferi", "icon": 1296},
]

const RING_BASES := [
	{"name": "Bakır Yüzük", "icon": 1866},
	{"name": "Altın Yüzük", "icon": 1871},
	{"name": "Yakut Yüzük", "icon": 1872},
	{"name": "Safir Yüzük", "icon": 1893},
	{"name": "Yakut Kolye", "icon": 1868},
	{"name": "İblis Yüzüğü", "icon": 1891},
]

const ENEMY_DEFS := {
	"goblin": {
		"name": "Orman Goblini", "spr": "sgob", "tint": Color(1, 1, 1), "sc": 1.0, "bar": 26.0,
		"hp": 36.0, "atk": 7.0, "def": 1.0, "spd": 48.0, "xp": 14, "gold": [5, 12],
		"lvl": 1, "gear": 0.14, "mats": [["monster_bone", 0.55], ["copper_ore", 0.25]],
	},
	"orc_rogue": {
		"name": "Goblin Haydutu", "spr": "sgob", "tint": Color(0.95, 0.72, 0.62), "sc": 1.0, "bar": 26.0,
		"hp": 54.0, "atk": 11.0, "def": 2.0, "spd": 62.0, "xp": 24, "gold": [9, 18],
		"lvl": 2, "gear": 0.18, "mats": [["monster_bone", 0.65], ["copper_ore", 0.3]],
	},
	"orc_shaman": {
		"name": "Goblin Şamanı", "spr": "sgob", "tint": Color(0.85, 0.8, 1.35), "sc": 1.0, "bar": 26.0,
		"hp": 52.0, "atk": 13.0, "def": 2.0, "spd": 44.0, "xp": 28, "gold": [10, 20],
		"lvl": 3, "gear": 0.20, "ranged": true, "proj_col": Color(0.45, 1.0, 0.45),
		"mats": [["mush_glow", 0.35], ["spirit_crystal", 0.12]],
	},
	"boss_grog": {
		"name": "GOBLİN SAVAŞ LORDU GROG", "spr": "sgob", "tint": Color(1.25, 0.82, 0.68), "sc": 2.5, "bar": 26.0,
		"hp": 480.0, "atk": 18.0, "def": 5.0, "spd": 54.0, "xp": 280, "gold": [250, 360],
		"lvl": 5, "gear": 1.0, "boss": true, "boss_id": "grog",
		"arena": Vector2(1960, 195), "trophy": "boss_trophy_orc",
		"mats": [["boss_trophy_orc", 1.0], ["copper_ore", 1.0], ["monster_bone", 1.0]],
	},
	"skeleton": {
		"name": "Maden İskeleti", "spr": "sskel", "tint": Color(1, 1, 1), "sc": 1.0, "bar": 26.0,
		"hp": 72.0, "atk": 14.0, "def": 3.5, "spd": 48.0, "xp": 34, "gold": [12, 24],
		"lvl": 4, "gear": 0.18, "mats": [["monster_bone", 0.85], ["gold_ore", 0.18]],
	},
	"skel_warrior": {
		"name": "İskelet Savaşçı", "spr": "sskel", "tint": Color(0.9, 0.9, 0.85), "sc": 1.5, "bar": 26.0,
		"hp": 110.0, "atk": 18.0, "def": 6.0, "spd": 52.0, "xp": 52, "gold": [18, 32],
		"lvl": 6, "gear": 0.24, "mats": [["monster_bone", 0.7], ["dark_essence", 0.35]],
	},
	"skel_rogue": {
		"name": "Gölge İskeleti", "spr": "sskel", "tint": Color(0.72, 0.76, 1.1), "sc": 1.0, "bar": 26.0,
		"hp": 88.0, "atk": 20.0, "def": 4.0, "spd": 66.0, "xp": 48, "gold": [16, 30],
		"lvl": 6, "gear": 0.22, "mats": [["dark_essence", 0.45], ["gold_ore", 0.2]],
	},
	"skel_mage": {
		"name": "İskelet Büyücü", "spr": "sskel", "tint": Color(0.8, 0.95, 1.3), "sc": 1.0, "bar": 26.0,
		"hp": 84.0, "atk": 22.0, "def": 4.0, "spd": 42.0, "xp": 60, "gold": [20, 35],
		"lvl": 7, "gear": 0.25, "ranged": true, "proj_col": Color(0.55, 0.8, 1.0),
		"mats": [["dark_essence", 0.6], ["spirit_crystal", 0.22]],
	},
	"boss_korgath": {
		"name": "KAN CANAVARI KORGATH", "spr": "blood", "tint": Color(1, 1, 1), "sc": 2.6,
		"hp": 950.0, "atk": 28.0, "def": 9.0, "spd": 56.0, "xp": 600, "gold": [500, 700],
		"lvl": 9, "gear": 1.0, "boss": true, "boss_id": "korgath",
		"arena": Vector2(2680, 310), "trophy": "boss_trophy_blood",
		"mats": [["boss_trophy_blood", 1.0], ["dark_essence", 1.0], ["gold_ore", 1.0]],
	},
	"shadow_knight": {
		"name": "Kızıl Gölge Şövalyesi", "spr": "sskel", "tint": Color(1.25, 0.6, 0.65), "sc": 1.5, "bar": 26.0,
		"hp": 195.0, "atk": 29.0, "def": 10.0, "spd": 56.0, "xp": 105, "gold": [34, 58],
		"lvl": 10, "gear": 0.38, "mats": [["dark_essence", 0.85], ["ancient_skull", 0.28]],
	},
	"hell_shaman": {
		"name": "Cehennem Büyücüsü", "spr": "sskel", "tint": Color(1.35, 0.7, 0.45), "sc": 1.0, "bar": 26.0,
		"hp": 150.0, "atk": 32.0, "def": 7.0, "spd": 46.0, "xp": 115, "gold": [36, 62],
		"lvl": 11, "gear": 0.36, "ranged": true, "proj_col": Color(1.0, 0.45, 0.25),
		"mats": [["dark_essence", 0.8], ["spirit_crystal", 0.4]],
	},
	"boss_malakor": {
		"name": "KIZIL İBLİS LORDU MALAKOR", "spr": "demon", "tint": Color(1, 1, 1), "sc": 2.8,
		"hp": 1800.0, "atk": 40.0, "def": 14.0, "spd": 58.0, "xp": 1400, "gold": [1100, 1500],
		"lvl": 14, "gear": 1.0, "boss": true, "boss_id": "malakor",
		"arena": Vector2(3260, 620), "trophy": "boss_trophy_demon",
		"mats": [["boss_trophy_demon", 1.0], ["ancient_skull", 1.0], ["spirit_crystal", 1.0]],
	},
	"slime_blue": {
		"name": "Maden Balçığı", "spr": "sgob", "tint": Color(0.4, 0.7, 1.2, 0.85), "sc": 0.85, "bar": 22.0,
		"hp": 45.0, "atk": 8.0, "def": 1.5, "spd": 55.0, "xp": 18, "gold": [6, 14],
		"lvl": 2, "gear": 0.15, "mats": [["slime_jelly", 0.75], ["copper_ore", 0.2]],
	},
	"void_stalker": {
		"name": "Boşluk Avcısı", "spr": "sskel", "tint": Color(0.65, 0.35, 0.95), "sc": 1.3, "bar": 26.0,
		"hp": 160.0, "atk": 26.0, "def": 8.0, "spd": 64.0, "xp": 95, "gold": [30, 50],
		"lvl": 9, "gear": 0.32, "mats": [["dark_essence", 0.7], ["void_crystal", 0.35]],
	},
	"boss_void_emperor": {
		"name": "KADİM BOŞLUK HÜKÜMDARI", "spr": "demon", "tint": Color(0.5, 0.2, 0.85), "sc": 3.1,
		"hp": 2600.0, "atk": 52.0, "def": 18.0, "spd": 60.0, "xp": 2200, "gold": [1800, 2500],
		"lvl": 18, "gear": 1.0, "boss": true, "boss_id": "void_emperor",
		"arena": Vector2(3400, 1100), "trophy": "boss_trophy_void",
		"mats": [["boss_trophy_void", 1.0], ["void_crystal", 1.0], ["spirit_crystal", 1.0]],
	},
}

const BOSS_LIST := [
	{"id": "grog", "def": "boss_grog", "zone": "Kuzey Harabesi", "lvl": 5, "drop": "Grog'un Savaş Baltası + Goblin Lordu Dişi"},
	{"id": "korgath", "def": "boss_korgath", "zone": "Kanlı Mahzen (Kuzeydoğu)", "lvl": 9, "drop": "Kan Dişi Kılıç + Kan Kristali"},
	{"id": "malakor", "def": "boss_malakor", "zone": "Cehennem Sunakı (En Doğu)", "lvl": 14, "drop": "Efsanevi İblis Seti + İblis Boynuzu"},
	{"id": "void_emperor", "def": "boss_void_emperor", "zone": "Derin Boşluk Boyutu (Güneydoğu)", "lvl": 18, "drop": "Tanrı Katı Boşluk Seti + Boşluk Kalbi"},
]

const ITEMS := {
	# Tools
	"hoe": {"name": "Çapa", "icon": 0, "type": "tool", "sell": 0, "desc": "Toprağı çapalayarak ekime hazır hale getirir."},
	"water": {"name": "Sulama Kabı", "icon": 4, "type": "tool", "sell": 0, "desc": "Çapalanmış toprağı sular. Kuyudan doldurulur."},
	"rod": {"name": "Olta", "icon": 6, "type": "tool", "sell": 0, "desc": "Güney Gölü kenarında balık tutmanı sağlar."},
	"axe": {"name": "Balta & Kazma", "icon": 7, "type": "tool", "sell": 0, "desc": "Ağaç keser ve maden kayalarını kırar."},
	"sword": {"name": "Silah", "icon": 9, "type": "tool", "sell": 0, "desc": "Kuşandığın kılıçla canavarlara saldırır."},
	"bone_tool": {"name": "Kemik", "icon": 10, "type": "tool", "sell": 0, "desc": "Karabaş'a fırlat: düşmana saldırır veya trüf kazar."},
	# Seeds
	"seed_parsnip": {"name": "Yaban Havucu Tohumu", "icon": 11, "type": "seed", "crop": "parsnip", "days": 2, "buy": 15, "sell": 7, "desc": "2 günde hızlı büyüyen lezzetli kök sebze."},
	"seed_carrot": {"name": "Havuç Tohumu", "icon": 11, "type": "seed", "crop": "carrot", "days": 2, "buy": 20, "sell": 10, "desc": "Turuncu, kıtır ve besleyici çiftlik havucu."},
	"seed_potato": {"name": "Patates Tohumu", "icon": 11, "type": "seed", "crop": "potato", "days": 3, "buy": 25, "sell": 12, "desc": "Yemeklerde ve satışta çok değerli patates."},
	"seed_sunflower": {"name": "Ayçiçeği Tohumu", "icon": 11, "type": "seed", "crop": "sunflower", "days": 3, "buy": 35, "sell": 18, "desc": "Yaz güneşini seven parlak sarı çiçek."},
	"seed_pumpkin": {"name": "Balkabağı Tohumu", "icon": 11, "type": "seed", "crop": "pumpkin", "days": 4, "buy": 50, "sell": 25, "desc": "Sonbahar hasadının dev altın kralı."},
	"seed_cabbage": {"name": "Lahana Tohumu", "icon": 11, "type": "seed", "crop": "cabbage", "days": 3, "buy": 30, "sell": 15, "desc": "Sebze güvecinin temel malzemesi."},
	# Crops
	"parsnip": {"name": "Yaban Havucu", "icon": 17, "type": "crop", "sell": 35, "hp": 15, "stam": 15, "desc": "Taze hasat edilmiş tatlı kök sebze."},
	"carrot": {"name": "Havuç", "icon": 12, "type": "crop", "sell": 45, "hp": 18, "stam": 18, "desc": "Enerji veren taze çiftlik havucu."},
	"potato": {"name": "Patates", "icon": 13, "type": "crop", "sell": 60, "hp": 20, "stam": 22, "desc": "Doyurucu altın patates."},
	"sunflower": {"name": "Ayçiçeği", "icon": 20, "type": "crop", "sell": 85, "hp": 10, "stam": 10, "desc": "Köylülerin bayıldığı parlak çiçek."},
	"pumpkin": {"name": "Dev Balkabağı", "icon": 14, "type": "crop", "sell": 135, "hp": 30, "stam": 35, "desc": "Tart yapımında kullanılan muazzam balkabağı."},
	"cabbage": {"name": "Yeşil Lahana", "icon": 16, "type": "crop", "sell": 75, "hp": 20, "stam": 20, "desc": "Sulu taze lahana başı."},
	# Animal products
	"egg": {"name": "Taze Yumurta", "icon": 22, "type": "animal", "sell": 40, "hp": 15, "stam": 18, "desc": "Mutlu tavuklardan her sabah toplanır."},
	"milk": {"name": "Çiftlik Sütü", "icon": 23, "type": "animal", "sell": 65, "hp": 25, "stam": 28, "desc": "Sıcak ve besleyici taze inek sütü."},
	# Forage & Mining
	"mush_red": {"name": "Kırmızı Orman Mantarı", "icon": 24, "type": "forage", "sell": 30, "hp": 10, "stam": 15, "desc": "Orman gölgelerinde yetişen simya mantarı."},
	"mush_glow": {"name": "Ay Işığı Mantarı", "icon": 25, "type": "forage", "sell": 70, "hp": 15, "stam": 25, "desc": "Parıldayan nadir gece mantarı. Ozan buna bayılır."},
	"truffle": {"name": "Kara Trüf", "icon": 26, "type": "forage", "sell": 160, "hp": 25, "stam": 35, "desc": "Karabaş'ın bulduğu nadir gurme trüf."},
	"wood": {"name": "Meşe Odunu", "icon": 27, "type": "mat", "sell": 6, "desc": "Ateş ve geliştirme için sağlam kereste."},
	"stone": {"name": "Taş", "icon": 28, "type": "mat", "sell": 5, "desc": "Maden kayalarından kırılan yapı taşı."},
	"copper_ore": {"name": "Bakır Cevheri", "icon": 29, "type": "mat", "sell": 25, "desc": "Demirci örsünde alet ve silah geliştirmek için eritilir."},
	"gold_ore": {"name": "Altın Cevheri", "icon": 30, "type": "mat", "sell": 65, "desc": "Usta seviye ekipmanlar için değerli maden."},
	"spirit_crystal": {"name": "Ruh Kristali", "icon": 44, "type": "mat", "sell": 150, "desc": "Orman ruhlarının ve bossların büyülü özü."},
	# Fish
	"fish_trout": {"name": "Nehir Alabalığı", "icon": 33, "type": "fish", "sell": 55, "hp": 20, "stam": 20, "desc": "Berrak göl sularında yaşayan çevik balık."},
	"fish_sun": {"name": "Gökkuşağı Balığı", "icon": 34, "type": "fish", "sell": 85, "hp": 25, "stam": 25, "desc": "Pulları güneş ışığında parlayan renkli balık."},
	"fish_koi": {"name": "Altın Koi", "icon": 35, "type": "fish", "sell": 180, "hp": 35, "stam": 40, "desc": "Şans ve bereket getiren nadir sazan."},
	"fish_eel": {"name": "Mistik Ay Müreni", "icon": 36, "type": "fish", "sell": 140, "hp": 30, "stam": 35, "desc": "Akşam saatlerinde gölde beliren gizemli balık."},
	# Cooked Dishes & Potions
	"meal_breakfast": {"name": "Çiftlik Kahvaltısı", "icon": 37, "type": "food", "sell": 130, "hp": 60, "stam": 65, "desc": "Yumurta ve sütle yapılan sıcacık kahvaltı."},
	"meal_fish": {"name": "Izgara Alabalık", "icon": 38, "type": "food", "sell": 145, "hp": 55, "stam": 60, "desc": "Odun ateşinde pişmiş enfes balık."},
	"meal_stew": {"name": "Sebze Güveci", "icon": 40, "type": "food", "sell": 170, "hp": 70, "stam": 75, "desc": "Patates, havuç ve lahana ile doyurucu güveç."},
	"meal_pie": {"name": "Altın Balkabağı Tartı", "icon": 39, "type": "food", "sell": 260, "hp": 90, "stam": 100, "desc": "Meryem'in en sevdiği meşhur köy tatlısı."},
	"meal_warrior": {"name": "Savaşçı Güveci", "icon": 40, "type": "food", "sell": 220, "hp": 85, "stam": 85, "atk_buff": 60.0, "desc": "85 Can yeniler ve 60 sn Saldırı Gücünü %25 artırır!"},
	"pot_growth": {"name": "Bereket İksiri", "icon": 41, "type": "potion", "sell": 120, "desc": "Çiftlikteki tüm ekinleri anında hasada hazırlar!"},
	"pot_rain": {"name": "Yağmur Totemi", "icon": 1902, "type": "potion", "sell": 140, "desc": "Gökyüzüne yağmur çağırır ve tüm tarlayı sular!"},
	"pot_spirit": {"name": "Ruh Şurubu", "icon": 43, "type": "potion", "sell": 110, "hp": 110, "stam": 100, "desc": "Canı ve enerjiyi fuller, 30 saniye ekstra hız verir."},
	"pot_heal": {"name": "Şifa İksiri", "icon": 1901, "type": "potion", "sell": 20, "hp": 80, "stam": 15, "desc": "Savaşta hızlıca 80 can yeniler. [H] tuşu ile iç."},
	"pot_iron": {"name": "Demir Deri İksiri", "icon": 1900, "type": "potion", "sell": 65, "hp": 25, "def_buff": 60.0, "desc": "60 sn boyunca +12 Savunma verir. Boss avında çok etkili!"},
	# Mob Loot & Boss Trophies
	"slime_jelly": {"name": "Mavi Balçık Jeli", "icon": 1530, "type": "loot", "sell": 18, "desc": "Zindan balçıklarından düşer. Simyada ve parşömenlerde kullanılır."},
	"void_crystal": {"name": "Boşluk Kristali", "icon": 1893, "type": "loot", "sell": 250, "desc": "Derin maden ve kadim iblislerin taşıdığı mor kristal."},
	"monster_bone": {"name": "Kemik Parçası", "icon": 2163, "type": "loot", "sell": 12, "desc": "Yenilen canavarlardan düşer. Demircide kullanılır."},
	"dark_essence": {"name": "Gölge Özü", "icon": 1563, "type": "loot", "sell": 45, "desc": "Gölge Ormanı yaratıklarının karanlık özü."},
	"ancient_skull": {"name": "Kadim Kafatası", "icon": 2167, "type": "loot", "sell": 120, "desc": "Çok nadir. Güçlü yaratıklardan düşer."},
	"boss_trophy_orc": {"name": "Goblin Lordu Dişi", "icon": 2163, "type": "loot", "sell": 180, "desc": "Boss Grog ganimeti! Demirci'de Nadir Boss Baltası döver."},
	"boss_trophy_blood": {"name": "Kan Kristali", "icon": 1534, "type": "loot", "sell": 320, "desc": "Boss Korgath ganimeti! Kan Şövalyesi Zırhı dövmekte kullanılır."},
	"boss_trophy_demon": {"name": "İblis Boynuzu", "icon": 2167, "type": "loot", "sell": 600, "desc": "Boss Malakor ganimeti! Efsanevi İblis Seti dövülür."},
	"boss_trophy_void": {"name": "Kadim Boşluk Kalbi", "icon": 1891, "type": "loot", "sell": 1200, "desc": "Gizli Boss Kadim Boşluk Hükümdarı ganimeti! Tanrı Katı ekipman döver."},
	# Özel İlişki & Romantizm Eşyaları (Stardew Valley Tarzı)
	"bouquet": {"name": "Vadi Çiçek Buketi", "icon": 20, "type": "gift", "buy": 250, "sell": 100, "desc": "Köylülerle derin bağ kurmanı sağlar. 4+ kalp olan köylüye verince özel aşk/kardeşlik diyaloğu açar!"},
	"mermaid_pendant": {"name": "Denizkızı Tılsımı", "icon": 1868, "type": "gift", "buy": 1500, "sell": 500, "desc": "Stardew efsanesi! 6 Kalp olan köy yoldaşına evlilik/ebedi yol arkadaşlığı teklif et!"},
	# Yeni Büyü & Menzilli Silah Parşömenleri
	"scroll_fireball": {"name": "Alev Topu Parşömeni", "icon": 1016, "type": "potion", "sell": 160, "desc": "Kullandığında en yakın 3 düşmana 120 Ateş Hasarı vuran alev topları fırlatır!"},
	"scroll_frost": {"name": "Buz Kasırgası Parşömeni", "icon": 1005, "type": "potion", "sell": 180, "desc": "Çevredeki tüm düşmanları dondurur ve 4 saniye boyunca %60 yavaşlatır!"},
}

# ---------------- STARDEW TARZI YAŞAYAN KOMŞULAR (6 KÖYLÜ) ----------------
const VILLAGERS := [
	{
		"id": "ayla",
		"name": "Ayla",
		"role": "Tohumcu & Çiftçi",
		"sheet": "npc_peasant",
		"portrait_bg": Color(0.24, 0.36, 0.22),
		"service": "shop",
		"service_label": "Tohum Dükkanı",
		"loved": ["sunflower", "meal_pie", "truffle"],
		"liked": ["parsnip", "carrot", "potato", "egg", "milk"],
		"perk3": "Tohum & tavuk dükkanında %15 kalıcı indirim!",
		"perk6": "Her sabah tarlaya rastgele şans gübresi (+25 Altın değeri)!",
		"schedule": [
			{"hour": 7, "pos": Vector2(1480, 470), "zone": "Tohum Dükkanı Önü"},
			{"hour": 13, "pos": Vector2(1545, 575), "zone": "Köy Meydanı"},
			{"hour": 18, "pos": Vector2(1465, 465), "zone": "Tohum Dükkanı"},
		],
		"greetings": [
			"Günaydın komşum! Toprağın kokusu bugün harika, değil mi?",
			"Her sabah ekinleri sulamak sabır ister ama hasadın sevinci bambaşka.",
			"Seninle sohbet etmek güne enerjik başlamamı sağlıyor, dostum!",
			"Çiftliğin vadiye yeniden hayat getirdi! Seninle gurur duyuyorum.",
		],
		"rain_line": "Yağmurlu günler benim en sevdiğim günler—sulama kabı dinlenir, ekinler coşar!",
		"boss_line": "Köyde herkes senin ormandaki canavarları alt ettiğini konuşuyor! Dikkatli ol kahraman!",
	},
	{
		"id": "demir",
		"name": "Demir",
		"role": "Usta Demirci",
		"sheet": "npc_knight",
		"portrait_bg": Color(0.28, 0.26, 0.32),
		"service": "smith",
		"service_label": "Demirci & Zırh Dükkanı",
		"loved": ["gold_ore", "boss_trophy_orc", "boss_trophy_demon"],
		"liked": ["copper_ore", "stone", "monster_bone", "meal_warrior"],
		"perk3": "Örs güçlendirmelerinde %15 altın indirimi!",
		"perk6": "Kalıcı +4 Saldırı ve +4 Savunma dövme ustalığı bonusu!",
		"schedule": [
			{"hour": 7, "pos": Vector2(1290, 560), "zone": "Demirci Atölyesi"},
			{"hour": 14, "pos": Vector2(1560, 620), "zone": "Meydan Ateşi"},
			{"hour": 18, "pos": Vector2(1300, 570), "zone": "Demirci Atölyesi"},
		],
		"greetings": [
			"Çelik soğumaz, bilek güçlenir. Kılıcın keskin olsun evlat.",
			"Kuzeyde Grog, mahzende Korgath, en doğuda Malakor... Zırhsız gitme!",
			"Senin gibi cesur bir savaşçıya kılıç dövmek onurdur.",
			"Çayır Vadisi'nin kalkanı sensin. Örsüm senin için her zaman sıcak!",
		],
		"rain_line": "Yağmur demir ocağımı söndüremez! Çeliği suyla tavlamak için harika bir gün.",
		"boss_line": "Boss ganimetlerini bana getir! Sana destansı zırh ve silah döveyim!",
	},
	{
		"id": "meryem",
		"name": "Meryem",
		"role": "Han Ustası & Aşçı",
		"sheet": "npc_tavern",
		"portrait_bg": Color(0.38, 0.25, 0.20),
		"service": "tavern",
		"service_label": "Han & İksir Tezgahı",
		"loved": ["meal_pie", "pumpkin", "truffle"],
		"liked": ["egg", "milk", "fish_trout", "fish_koi", "carrot"],
		"perk3": "Han yemek ve şifa iksirlerinde %15 indirim!",
		"perk6": "Her gün ilk konuşmada sıcak Çiftlik Kahvaltısı ikramı!",
		"schedule": [
			{"hour": 7, "pos": Vector2(1775, 470), "zone": "Gül Hanı Önü"},
			{"hour": 13, "pos": Vector2(1655, 620), "zone": "Meydan Ateşi"},
			{"hour": 17, "pos": Vector2(1775, 470), "zone": "Gül Hanı"},
		],
		"greetings": [
			"Hoş geldin tatlım! Çorba kaynıyor, iksirler taze!",
			"Savaşta [H] tuşuyla hemen şifa içebilirsin, sakın unutma.",
			"Yüzün güldüğünde hanımız da aydınlanıyor canım komşum!",
			"Sen olmasan köyümüz bu kadar güvenli ve neşeli olamazdı!",
		],
		"rain_line": "Dışarısı ıslakken hanın ateşi başında sıcak güveç gibisi yoktur!",
		"boss_line": "İnanamıyorum, dev canavarı devirmişsin! Bugün yemekler neredeyse bedava sayılır!",
	},
	{
		"id": "ozan",
		"name": "Bilge Ozan",
		"role": "Simyacı & Büyücü",
		"sheet": "npc_wizard",
		"portrait_bg": Color(0.24, 0.20, 0.38),
		"service": "alchemy_shop",
		"service_label": "Simya & Tılsım Tezgahı",
		"loved": ["mush_glow", "spirit_crystal", "boss_trophy_blood"],
		"liked": ["mush_red", "dark_essence", "ancient_skull", "pot_spirit"],
		"perk3": "Kalıcı +8% Kritik Şansı rün kutsaması!",
		"perk6": "Maksimum Canına kalıcı +30 Can rünü işlenir!",
		"schedule": [
			{"hour": 7, "pos": Vector2(1615, 725), "zone": "Köy Meydanı"},
			{"hour": 13, "pos": Vector2(1710, 680), "zone": "Meydan Bahçesi"},
			{"hour": 18, "pos": Vector2(1615, 665), "zone": "Meydan Ateşi"},
		],
		"greetings": [
			"Yıldızlar doğudaki Gölge Ormanı'nda kadim bir hareketlilik fısıldıyor...",
			"Mor ve turuncu parlayan ganimetler kadim güç taşır. [C] ile kuşan!",
			"Ruhun hem toprağa hem kılıca dengeyle hükmediyor genç dostum.",
			"Vadinin en bilge koruyucusuyla sohbet etmek benim için şeref.",
		],
		"rain_line": "Yağmur damlaları kadim rünlerin enerjisini açığa çıkarır.",
		"boss_line": "Karanlık mühürlerden birini kırdın! Karanlık özler üzerinde ışık parlıyor.",
	},
	{
		"id": "bram",
		"name": "Kaptan Bram",
		"role": "Göl Balıkçısı & Avcı",
		"sheet": "npc_rogue",
		"portrait_bg": Color(0.18, 0.30, 0.38),
		"service": "fisher_trade",
		"service_label": "Balıkçı & Avcı Takası",
		"loved": ["fish_koi", "fish_eel", "meal_fish"],
		"liked": ["fish_trout", "fish_sun", "wood", "pot_iron"],
		"perk3": "Balık ve av ganimeti satışından +%20 ekstra altın!",
		"perk6": "Kalıcı +10% Hareket & Saldırı çevikliği rüzgar tılsımı!",
		"schedule": [
			{"hour": 7, "pos": Vector2(780, 1085), "zone": "Güney Gölü İskelesi"},
			{"hour": 15, "pos": Vector2(1585, 650), "zone": "Köy Meydanı"},
			{"hour": 18, "pos": Vector2(780, 1085), "zone": "Güney Gölü İskelesi"},
		],
		"greetings": [
			"Ahoy! Sular bugün sakin, oltan [5] elinin altında olsun!",
			"Akşam 18:00'dan sonra gölde efsanevi Ay Müreni yakalayabilirsin.",
			"Deniz kurtları sadık dostları hemen tanır—sen de onlardan birisin!",
			"Hem gölün hem ormanın hakimi oldun be evlat!",
		],
		"rain_line": "Yağmur yağarken büyük balıklar yüzeye yaklaşır, tam av zamanı!",
		"boss_line": "Büyük canavarı devirdiğini duydum! Gölün bile dalgaları selam duruyor!",
	},
	{
		"id": "lina",
		"name": "Lina",
		"role": "Gezgin Tüccar & Koleksiyoncu",
		"sheet": "npc_tavern_b",
		"portrait_bg": Color(0.32, 0.22, 0.34),
		"service": "loot_buyer",
		"service_label": "Nadir Eşya & Tılsım Dükkanı",
		"loved": ["ancient_skull", "spirit_crystal", "fish_koi"],
		"liked": ["sunflower", "dark_essence", "mush_glow", "pumpkin"],
		"perk3": "Tüm ekipman ve ganimet satışlarında +%20 fazla altın!",
		"perk6": "Canavar düşen ganimetlerde Nadir/Destansı şansı +%15 artar!",
		"schedule": [
			{"hour": 7, "pos": Vector2(1665, 535), "zone": "İlan Panosu Yanı"},
			{"hour": 14, "pos": Vector2(1410, 565), "zone": "Köy Pazarı"},
			{"hour": 18, "pos": Vector2(1690, 620), "zone": "Meydan Ateşi"},
		],
		"greetings": [
			"Merhaba maceracı! Gölge Ormanı'ndan nadir hazineler getirdin mi?",
			"Komşulara her gün hediye verip konuşursan sana harika bonuslar açarlar!",
			"Benim favori müşterim ve en sevdiğim komşum gelmiş!",
			"Vadi senin sayende eski görkemine kavuştu, efsanesin!",
		],
		"rain_line": "Yağmur altında bile ticaret durmaz—çaylar benden!",
		"boss_line": "Boss kupalarını ve fazla zırhlarını değerinin üstünde alabilirim!",
	},
]

const STORY_CHAPTERS := [
	{"title": "1. Yeni Çiftlik Hayatı", "desc": "Tarlanı çapala [2], sula [3] ve 3 tohum ek [6].", "need": 3, "reward_gold": 140, "reward_item": "seed_carrot", "reward_cnt": 4},
	{"title": "2. Köy Komşuları", "desc": "Köy Meydanına git, bir komşuyla sohbet et veya hediye ver [E].", "need": 1, "reward_gold": 160, "reward_item": "sunflower", "reward_cnt": 2},
	{"title": "3. Demirci & Zırh", "desc": "Demirci Demir'den bir Zırh veya Kalkan al ve [C] ile kuşan!", "need": 1, "reward_gold": 180, "reward_item": "pot_heal", "reward_cnt": 3},
	{"title": "4. Kuzey Ormanı Avı", "desc": "Kuzey Ormanına git, Silahını [1] seç ve 5 canavar yen.", "need": 5, "reward_gold": 240, "reward_item": "pot_iron", "reward_cnt": 2},
	{"title": "5. İlk Boss: Savaş Lordu Grog", "desc": "Kuzeydoğu Harabesinde GOBLİN SAVAŞ LORDU GROG'u yen!", "need": 1, "reward_gold": 450, "reward_item": "meal_warrior", "reward_cnt": 2},
	{"title": "6. Evini Geliştir & Göl", "desc": "Evine gir [E], Düzenleme Masasında Ev Mutfağı kur veya Güney Gölünde balık tut.", "need": 1, "reward_gold": 280, "reward_item": "gold_ore", "reward_cnt": 3},
	{"title": "7. Gölge Mahzeni", "desc": "Gölge Ormanında 6 yaratık yen ve seviye atla!", "need": 6, "reward_gold": 550, "reward_item": "pot_heal", "reward_cnt": 5},
	{"title": "8. İkinci Boss: Kan Canavarı", "desc": "Kanlı Mahzen arenasında KAN CANAVARI KORGATH'ı yen!", "need": 1, "reward_gold": 900, "reward_item": "spirit_crystal", "reward_cnt": 3},
	{"title": "9. Efsanevi Hazırlık", "desc": "Demirci Örsünde silahını güçlendir veya Boss ekipmanı döv.", "need": 1, "reward_gold": 700, "reward_item": "pot_iron", "reward_cnt": 3},
	{"title": "10. Son Boss: İblis Lordu Malakor", "desc": "En doğudaki Cehennem Sunakında KIZIL İBLİS MALAKOR'u yen!", "need": 1, "reward_gold": 3000, "reward_item": "ancient_skull", "reward_cnt": 3},
]

# ---------------- AŞAMALI EV GELİŞTİRME & İÇ DEKORASYON ----------------
const HOUSE_UPGRADES := [
	{
		"id": "kitchen",
		"name": "Ev Mutfağı & Ocak",
		"min_lvl": 1,
		"need_boss": "",
		"gold": 120,
		"mats": {"wood": 8, "stone": 4},
		"desc": "Evinin içine sıcak ocak ve tezgah kurar. Güçlendirici yemekler pişir!",
	},
	{
		"id": "alchemy",
		"name": "Simya Masası",
		"min_lvl": 3,
		"need_boss": "",
		"gold": 220,
		"mats": {"wood": 10, "mush_red": 2, "copper_ore": 2},
		"desc": "Evinin köşesine büyülü simya masası ekler. İksir ve totemler üret!",
	},
	{
		"id": "forge",
		"name": "Kişisel Örs & Silahlık",
		"min_lvl": 4,
		"need_boss": "grog",
		"gold": 320,
		"mats": {"stone": 10, "copper_ore": 4},
		"desc": "Evinde silah/zırh güçlendirme ve Boss seti dövme atölyesi açar! (Boss 1 Grog)",
	},
	{
		"id": "grand_home",
		"name": "Lüks Şömine & Çift Yatak",
		"min_lvl": 5,
		"need_boss": "",
		"gold": 420,
		"mats": {"wood": 15, "stone": 10, "gold_ore": 2},
		"desc": "Büyük taş şömine, geniş yatak ve sabahları Dinlenmiş (+%15 Can) bonusu!",
	},
]

const HOUSE_FLOORS := ["Meşe Tahta", "Balıksırtı Parke", "Taş Döşeme", "Altın Çam"]
const HOUSE_RUGS := ["Hasır Halı", "Orman Yeşili", "Kraliyet Kırmızı", "Halısız"]
const HOUSE_WALLS := ["Krem Sıva & Ahşap", "Kütük Duvar", "Şövalye Taşı"]
const HOUSE_DECOR_TOGGLES := [
	{"id": "plants", "name": "Saksı Çiçekleri"},
	{"id": "dining", "name": "Yemek Masası & Kitaplık"},
	{"id": "dog_corner", "name": "Karabaş Mama Köşesi"},
	{"id": "wall_art", "name": "Tablo & Duvar Silahları"},
]

# İkon paketi 4 (Gemini) — kültüre göre yüzsüz siluet portreler (bakan, lider, subay)

Kabine kartlarında ve atama penceresinde bakanlar artık ülkenin kültürüne göre giyinmiş siluetlerle görünsün diye.
Yüz YOK (etnik karikatür riski sıfır): kültürü başlık, kıyafet ve saç/duruş siluetiyle anlatıyoruz.
Tek görsel, 8 sütun x 6 satır = 48 portre = 12 kültür x 4 (sivil erkek, sivil kadın, subay erkek, subay kadın).

## Gemini istemi
```
Create ONE image: a clean 8 columns x 6 rows grid of 48 separate bust portraits of government officials on a plain solid flat magenta (#FF00FF) background. Each portrait sits inside its own dark navy rounded square tile, equal sizes, with a small gap between tiles. Style: faceless flat vector portrait for a mobile strategy game (World Empire 2027 / Age of Civilizations II feel): head and neck shown as a smooth FEATURELESS silhouette (NO eyes, NO nose, NO mouth, NO face details), filled with one uniform dark slate-grey (#2b3340) with a thin light cream outline, head-and-shoulders view facing front, centered, identical framing and scale in every tile. The culture is told ONLY by clothing, headwear and hair/head-covering silhouette, drawn with simple bold shapes, saturated but slightly muted colors, clean dark outline, one soft highlight. Dignified, respectful, NOT caricature, no stereotypes beyond real traditional or formal dress. Military officers wear a peaked cap or beret with epaulettes, medals and a collar insignia in the culture's formal uniform style (neutral, no real national insignia, no flags). NO labels, NO text; the magenta must not appear inside the portraits. Fill the grid left-to-right, top-to-bottom. Each row holds TWO cultures, four tiles each; inside each group of four the order is always: 1) civilian man, 2) civilian woman, 3) military officer man, 4) military officer woman.
Row 1: LEFT four tiles = Western (USA, Western Europe, Japan, Korea): dark business suit, white shirt, tie. RIGHT four tiles = Russia / Eastern & Northern Europe: heavy winter coat with a fur collar and a fur ushanka hat. Order inside each group of four: civilian man, civilian woman, military officer man, military officer woman.
Row 2: LEFT four tiles = Turkic / Central Asia / Caucasus: dark suit with a subtle embroidered collar band and a traditional kalpak or tubeteika cap. RIGHT four tiles = Arab Gulf: white thobe with a white ghutra headcloth and black agal cord. Order inside each group of four: civilian man, civilian woman, military officer man, military officer woman.
Row 3: LEFT four tiles = Levant / North Africa: dark suit with a checkered keffiyeh scarf over the shoulders. RIGHT four tiles = Iran / Afghanistan / Pakistan: collarless dark suit jacket without a tie, or a long sherwani-style coat with a turban-like cap. Order inside each group of four: civilian man, civilian woman, military officer man, military officer woman.
Row 4: LEFT four tiles = South Asia (India, Bangladesh, Sri Lanka, Nepal): cream Nehru jacket (stand collar) with a white Gandhi cap. RIGHT four tiles = China / Mongolia / Taiwan: dark Zhongshan-style jacket with a stand collar and buttons. Order inside each group of four: civilian man, civilian woman, military officer man, military officer woman.
Row 5: LEFT four tiles = Southeast Asia (Indonesia, Malaysia, Thailand, Vietnam, Philippines): batik-patterned long-sleeve shirt, a black songkok cap for the man. RIGHT four tiles = Sub-Saharan Africa: colorful agbada robe with kente-pattern stole. Order inside each group of four: civilian man, civilian woman, military officer man, military officer woman.
Row 6: LEFT four tiles = Latin America: light guayabera shirt with a presidential sash across the chest. RIGHT four tiles = Pacific / Oceania: dark shirt with a lavalava wrap and a flower garland (lei) around the neck. Order inside each group of four: civilian man, civilian woman, military officer man, military officer woman.
```

## Kültürlerin ayrıntısı (her satırda ne var)
- **west**: Western (USA, Western Europe, Japan, Korea): dark business suit, white shirt, tie
- **slav**: Russia / Eastern & Northern Europe: heavy winter coat with a fur collar and a fur ushanka hat
- **turk**: Turkic / Central Asia / Caucasus: dark suit with a subtle embroidered collar band and a traditional kalpak or tubeteika cap
- **gulf**: Arab Gulf: white thobe with a white ghutra headcloth and black agal cord
- **lev**: Levant / North Africa: dark suit with a checkered keffiyeh scarf over the shoulders
- **pers**: Iran / Afghanistan / Pakistan: collarless dark suit jacket without a tie, or a long sherwani-style coat with a turban-like cap
- **sasia**: South Asia (India, Bangladesh, Sri Lanka, Nepal): cream Nehru jacket (stand collar) with a white Gandhi cap
- **easia**: China / Mongolia / Taiwan: dark Zhongshan-style jacket with a stand collar and buttons
- **seasia**: Southeast Asia (Indonesia, Malaysia, Thailand, Vietnam, Philippines): batik-patterned long-sleeve shirt, a black songkok cap for the man
- **afr**: Sub-Saharan Africa: colorful agbada robe with kente-pattern stole
- **latam**: Latin America: light guayabera shirt with a presidential sash across the chest
- **pac**: Pacific / Oceania: dark shirt with a lavalava wrap and a flower garland (lei) around the neck

## Kesme
`python3 tools/slice_icons.py sayfa4.png 8 6 --set=pack4 --tiles` → `assets/icons/pt_<kültür>_<m|f|mm|fm>_c.png`
(m = sivil erkek, f = sivil kadın, mm = subay erkek, fm = subay kadın). Dosyaları koyunca haber ver; siluet sistemini bunlara bağlar, ülkeleri kültürlere eşlerim.

## Ülke -> kültür eşlemesi (benim tarafımda)
| Kod | Kültür | Örnek ülkeler |
|---|---|---|
| west | Batı | ABD, Kanada, Batı Avrupa, Japonya, G. Kore, Avustralya, Türkiye |
| slav | Slav/Kuzey | Rusya, Belarus, Ukrayna, Polonya, İskandinavya, Baltık |
| turk | Türk/İç Asya/Kafkas | Azerbaycan, Kazakistan, Özbekistan, Türkmenistan, Gürcistan, Balkanlar |
| gulf | Körfez Arabı | Suudi Arabistan, BAE, Katar, Kuveyt, Umman, Yemen |
| lev | Levant/K. Afrika | Mısır, Suriye, Lübnan, Ürdün, Libya, Tunus, Cezayir, Fas |
| pers | Fars/Afgan/Pakistan | İran, Afganistan, Pakistan, Tacikistan |
| sasia | Güney Asya | Hindistan, Bangladeş, Sri Lanka, Nepal |
| easia | Doğu Asya | Çin, Moğolistan, Tayvan, K. Kore |
| seasia | Güneydoğu Asya | Endonezya, Malezya, Tayland, Vietnam, Filipinler |
| afr | Sahra Altı Afrika | Nijerya, Kenya, Etiyopya, Güney Afrika, Gana... |
| latam | Latin Amerika | Meksika, Brezilya, Arjantin, Kolombiya... |
| pac | Pasifik | Yeni Zelanda, Fiji, Papua Yeni Gine, Samoa... |

## Liste
| Dosya | Anlamı |
|---|---|
| `pt_west_m_c.png` | west — sivil erkek |
| `pt_west_f_c.png` | west — sivil kadın |
| `pt_west_mm_c.png` | west — subay erkek |
| `pt_west_fm_c.png` | west — subay kadın |
| `pt_slav_m_c.png` | slav — sivil erkek |
| `pt_slav_f_c.png` | slav — sivil kadın |
| `pt_slav_mm_c.png` | slav — subay erkek |
| `pt_slav_fm_c.png` | slav — subay kadın |
| `pt_turk_m_c.png` | turk — sivil erkek |
| `pt_turk_f_c.png` | turk — sivil kadın |
| `pt_turk_mm_c.png` | turk — subay erkek |
| `pt_turk_fm_c.png` | turk — subay kadın |
| `pt_gulf_m_c.png` | gulf — sivil erkek |
| `pt_gulf_f_c.png` | gulf — sivil kadın |
| `pt_gulf_mm_c.png` | gulf — subay erkek |
| `pt_gulf_fm_c.png` | gulf — subay kadın |
| `pt_lev_m_c.png` | lev — sivil erkek |
| `pt_lev_f_c.png` | lev — sivil kadın |
| `pt_lev_mm_c.png` | lev — subay erkek |
| `pt_lev_fm_c.png` | lev — subay kadın |
| `pt_pers_m_c.png` | pers — sivil erkek |
| `pt_pers_f_c.png` | pers — sivil kadın |
| `pt_pers_mm_c.png` | pers — subay erkek |
| `pt_pers_fm_c.png` | pers — subay kadın |
| `pt_sasia_m_c.png` | sasia — sivil erkek |
| `pt_sasia_f_c.png` | sasia — sivil kadın |
| `pt_sasia_mm_c.png` | sasia — subay erkek |
| `pt_sasia_fm_c.png` | sasia — subay kadın |
| `pt_easia_m_c.png` | easia — sivil erkek |
| `pt_easia_f_c.png` | easia — sivil kadın |
| `pt_easia_mm_c.png` | easia — subay erkek |
| `pt_easia_fm_c.png` | easia — subay kadın |
| `pt_seasia_m_c.png` | seasia — sivil erkek |
| `pt_seasia_f_c.png` | seasia — sivil kadın |
| `pt_seasia_mm_c.png` | seasia — subay erkek |
| `pt_seasia_fm_c.png` | seasia — subay kadın |
| `pt_afr_m_c.png` | afr — sivil erkek |
| `pt_afr_f_c.png` | afr — sivil kadın |
| `pt_afr_mm_c.png` | afr — subay erkek |
| `pt_afr_fm_c.png` | afr — subay kadın |
| `pt_latam_m_c.png` | latam — sivil erkek |
| `pt_latam_f_c.png` | latam — sivil kadın |
| `pt_latam_mm_c.png` | latam — subay erkek |
| `pt_latam_fm_c.png` | latam — subay kadın |
| `pt_pac_m_c.png` | pac — sivil erkek |
| `pt_pac_f_c.png` | pac — sivil kadın |
| `pt_pac_mm_c.png` | pac — subay erkek |
| `pt_pac_fm_c.png` | pac — subay kadın |

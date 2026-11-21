--!strict
-- ============================================================
--  CATATAN
--  Popup klik lama ("+X Clicks!" kotak panjang) dan handler klik
--  global di file ini sudah dihapus.
--
--  Sekarang SEMUA klik ditangani oleh ClickerUIClientController:
--    - hanya tombol klik besar / klik di dunia yang dihitung
--    - efek "+1" muncul di posisi acak, tidak menumpuk
--    - tidak ada popup dobel dari server
--
--  File ini sengaja dibiarkan kosong agar tidak ada dua sistem
--  klik yang berjalan bersamaan.
-- ============================================================

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

print("[CoreLoopClientController] mode HUD tunggal aktif untuk " .. LocalPlayer.Name)

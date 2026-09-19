#!/usr/bin/env bash
# ==============================================================================
# Docker Hands-on Lab: İnteraktif Arıza Teşhis ve Çözüm Simülatörü
# Modül: LAB-DOC-11 — Troubleshooting Challenge
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIOS_DIR="${SCRIPT_DIR}/scenarios"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

cleanup_all() {
  echo -e "${YELLOW}==> Test konteynerleri ve ağları temizleniyor...${NC}"
  docker rm -f port-occupier fixed-port-web broken-port-web exit-web memory-crasher srv-db srv-app perm-app 2>/dev/null || true
  docker network rm custom-net 2>/dev/null || true
  rm -rf /tmp/perm-test 2>/dev/null || true
  echo -e "${GREEN}==> Tüm test ortamı temizlendi.${NC}"
}

run_scenario_menu() {
  local scen_num="$1"
  local scen_name="$2"
  local scen_folder="$3"
  local folder_path="${SCENARIOS_DIR}/${scen_folder}"

  while true; do
    echo ""
    echo -e "${CYAN}==================================================================${NC}"
    echo -e "${BOLD}📍 Aktif Senaryo: SCEN-0${scen_num} — ${scen_name}${NC}"
    echo -e "${CYAN}==================================================================${NC}"
    echo "  [B] 💣 Arızayı Başlat (Break - Sistemi boz ve hatayı üret)"
    echo "  [V] 🔍 Çözümü Doğrula (Verify - Düzeltmeyi otomatik test et)"
    echo "  [H] 💡 İpucu Al (Hint - Nereden başlamalıyım?)"
    echo "  [S] 🔑 Çözümü Göster ve Uygula (Solution)"
    echo "  [C] 🧹 Bu Senaryoyu Temizle"
    echo "  [R] ↩️  Ana Menüye Dön"
    echo ""
    read -rp "Seçiminiz [B, V, H, S, C, R]: " SUB_CHOICE

    case "$SUB_CHOICE" in
      [Bb])
        echo ""
        echo -e "${RED}==> Arıza enjekte ediliyor...${NC}"
        "${folder_path}/break.sh"
        echo ""
        echo -e "${YELLOW}👉 Şimdi terminalinizden arızayı inceleyin ve onarın.${NC}"
        echo "   Sorunu çözdüğünüzde [V] ile doğrulayın!"
        ;;
      [Vv])
        echo ""
        echo -e "${BLUE}==> Çözüm doğrulanıyor...${NC}"
        "${folder_path}/verify.sh"
        ;;
      [Hh])
        echo ""
        if [ -f "${folder_path}/hint.txt" ]; then
          cat "${folder_path}/hint.txt"
        else
          echo "Bu senaryo için ipucu dosyası bulunamadı."
        fi
        ;;
      [Ss])
        echo ""
        read -rp "Çözümü otomatik uygulamak istiyor musunuz? (e/h): " CONFIRM
        if [[ "$CONFIRM" =~ ^[eEyY]$ ]]; then
          echo -e "${GREEN}==> Çözüm uygulanıyor...${NC}"
          "${folder_path}/solution.sh"
          echo -e "${GREEN}==> Çözüm uygulandı. [V] ile doğrulayabilirsiniz.${NC}"
        fi
        ;;
      [Cc])
        echo ""
        echo -e "${YELLOW}==> Senaryo temizleniyor...${NC}"
        case "$scen_num" in
          1) docker rm -f port-occupier fixed-port-web broken-port-web 2>/dev/null || true ;;
          2) docker rm -f exit-web 2>/dev/null || true ;;
          3) docker rm -f memory-crasher 2>/dev/null || true ;;
          4) docker rm -f srv-db srv-app 2>/dev/null || true; docker network rm custom-net 2>/dev/null || true ;;
          5) docker rm -f perm-app 2>/dev/null || true; rm -rf /tmp/perm-test 2>/dev/null || true ;;
        esac
        echo -e "${GREEN}==> Temizlendi.${NC}"
        ;;
      [Rr])
        break
        ;;
      *)
        echo -e "${RED}Geçersiz seçim! Lütfen B, V, H, S, C veya R girin.${NC}"
        ;;
    esac
  done
}

while true; do
  clear || true
  echo -e "${CYAN}==================================================================${NC}"
  echo -e "${BOLD} 🐳  Docker Lab: İnteraktif Arıza ve Çözüm Simülatörü (CTF)${NC}"
  echo -e "${CYAN}==================================================================${NC}"
  echo "Bu araç; Docker ortamında gerçek üretim arızalarını simüle eder ve"
  echo "adım adım kök neden analizi (RCA) yaparak çözmenizi otomatik test eder."
  echo ""
  echo -e "${YELLOW}Lütfen bir arıza senaryosu seçin:${NC}"
  echo "  [1] SCEN-01: Port Çakışması (Port Already in Use)"
  echo "  [2] SCEN-02: Anında Kapanan Konteyner (Exit Code 0 / PID 1 Eksikliği)"
  echo "  [3] SCEN-03: Bellek Aşımı ve Çökme (OOMKilled Exit Code 137)"
  echo "  [4] SCEN-04: Konteynerlar Arası DNS İletişim Hatası (Default Bridge)"
  echo "  [5] SCEN-05: Volume Erişim Reddi (Permission Denied / UID Mismatch)"
  echo "  --------------------------------------------------------------"
  echo "  [C] 🧹 Tüm Test Konteynerlerini ve Ağlarını Temizle (Cleanup)"
  echo "  [Q] 🚪 Çıkış (Quit)"
  echo ""
  read -rp "Seçiminiz [1-5, C, Q]: " MAIN_CHOICE

  case "$MAIN_CHOICE" in
    1)
      run_scenario_menu 1 "Port Çakışması" "01-port-conflict"
      ;;
    2)
      run_scenario_menu 2 "Anında Kapanan Konteyner (Exit Code 0)" "02-exited-zero-daemon"
      ;;
    3)
      run_scenario_menu 3 "Bellek Aşımı (OOMKilled 137)" "03-oomkilled-137"
      ;;
    4)
      run_scenario_menu 4 "Konteynerlar Arası DNS İletişim Hatası" "04-bridge-dns"
      ;;
    5)
      run_scenario_menu 5 "Volume Erişim Reddi (Permission Denied)" "05-volume-permission"
      ;;
    [Cc])
      echo ""
      cleanup_all
      sleep 1.5
      ;;
    [Qq])
      echo ""
      echo "İyi çalışmalar dileriz!"
      exit 0
      ;;
    *)
      echo -e "${RED}Geçersiz seçim!${NC}"
      sleep 1
      ;;
  esac
done

#!/bin/bash

generate_report() {
    ensure_state_dir
    local report_dir="$SCRIPT_DIR/reports" report
    mkdir -p "$report_dir"
    report="$report_dir/report_$(date +%F_%H-%M-%S).txt"
    {
        echo "===== HRSAJ DEPLOY ====="
        echo "Data: $(date '+%F %T')"
        echo "Hostname: $(hostname)"
        echo
        echo "Estado dos módulos:"
        [ -s "$STATE_FILE" ] && cat "$STATE_FILE" || echo "Sem histórico"
        echo
        echo "Impressoras:"
        lpstat -p -d 2>/dev/null || echo "Nenhuma fila ou CUPS indisponível"
        echo
        echo "Rede:"
        ip -brief address 2>/dev/null || true
    } > "$report"
    cp "$report" "$STATE_DIR/last-report.txt"
    chmod 0644 "$STATE_DIR/last-report.txt"
    state_mark_ok report "$report"
    log_ok "Relatório gerado: $report"
}

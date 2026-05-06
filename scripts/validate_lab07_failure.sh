#!/usr/bin/env bash
set -o pipefail

SERVICE_IP="$1"

if [ -z "$SERVICE_IP" ]; then
  echo "Usage: $0 <service-ip>"
  exit 2
fi

REPORT_DIR="reports/lab07"
mkdir -p "$REPORT_DIR"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
REPORT_FILE="$REPORT_DIR/validate-${SERVICE_IP}-${TIMESTAMP}.log"

echo "Validating service: $SERVICE_IP"
echo "Report: $REPORT_FILE"
echo

ansible-playbook playbooks/verify_lab06_transport_resolution.yml > "$REPORT_FILE" 2>&1
ANSIBLE_RC=$?

grep -E '"ASSERT .* ->' "$REPORT_FILE" | awk '
  /"msg": "ASSERT/ {
    sub(/^.*"msg": "/, "")
    sub(/"$/, "")
    print
  }
' "$REPORT_FILE"

if [ "$ANSIBLE_RC" -ne 0 ]; then
  echo
  echo "RESULT: ERROR"
  echo "Ansible playbook failed. Full output saved to: $REPORT_FILE"
  exit 2
fi

if grep -q "ASSERT .* -> FAIL" "$REPORT_FILE"; then
  echo
  echo "RESULT: FAIL"
    echo
  echo "DIAGNOSIS:"

  if grep -q "ASSERT route color -> FAIL" "$REPORT_FILE" && \
     grep -q "ASSERT transport class -> FAIL" "$REPORT_FILE" && \
     grep -q "ASSERT gold transport marker -> PASS" "$REPORT_FILE"; then

    echo "- Service classification failure"
    echo "- Cause: service route is missing expected color/community"
    echo "- Impact: cannot map to gold transport, fallback likely"
  fi
  echo "Full output saved to: $REPORT_FILE"
  exit 1
fi

echo
echo "RESULT: PASS"
echo "Full output saved to: $REPORT_FILE"
exit 0
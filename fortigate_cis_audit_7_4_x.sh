#!/bin/bash

# ============================================================
#  CIS FortiGate 7.4.x Benchmark v1.0.1 Audit Script
#  Tested against FortiOS 7.4.x series
# ============================================================

log() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message"
}

# ============================================================
# SECTION 1 - NETWORK SETTINGS
# ============================================================

# 1.1 Ensure DNS server is configured (Automated)
check_dns_configuration() {
    local config_file="$1"
    local output=""
    if grep -q "config system dns" "$config_file"; then
        if awk '/config system dns/,/^end/' "$config_file" | grep -q "set primary"; then
            output="PASS: DNS server is configured"
        else
            output="FAIL: DNS primary server is not set under config system dns"
        fi
    else
        output="FAIL: DNS server is not configured (config system dns block missing)"
    fi
    echo "$output"
}

# 1.2 Ensure intra-zone traffic is not always allowed (Automated)
# 7.4.x CLI key: set intrazone-deny enable  (under config system settings)
check_intra_zone_traffic() {
    local config_file="$1"
    local output=""
    if grep -q "set intrazone-deny enable" "$config_file"; then
        output="PASS: Intra-zone traffic is restricted (intrazone-deny enable)"
    else
        output="FAIL: Intra-zone traffic may be always allowed (intrazone-deny enable not found)"
    fi
    echo "$output"
}

# 1.3 Disable all management related services on WAN port (Automated)
check_wan_management_services() {
    local config_file="$1"
    local output=""
    if awk '/config system interface/,/^end/' "$config_file" | \
        grep -E "set allowaccess.*(https|http|ssh|telnet)" | grep -v "^#" | grep -q "."; then
        output="FAIL: Management-related services (http/https/ssh/telnet) appear enabled on an interface - verify WAN interface"
    else
        output="PASS: No management-related services detected on interfaces (verify WAN interface manually)"
    fi
    echo "$output"
}

# ============================================================
# SECTION 2 - SYSTEM SETTINGS
# ============================================================

# 2.1.1 Ensure Pre-Login Banner is set (Automated)
check_pre_login_banner() {
    local config_file="$1"
    local output=""
    if awk '/config system global/,/^end/' "$config_file" | grep -q "set pre-login-banner"; then
        output="PASS: Pre-Login Banner is set"
    else
        output="FAIL: Pre-Login Banner is not set (set pre-login-banner missing in config system global)"
    fi
    echo "$output"
}

# 2.1.2 Ensure Post-Login Banner is set (Automated)
check_post_login_banner() {
    local config_file="$1"
    local output=""
    if awk '/config system global/,/^end/' "$config_file" | grep -q "set post-login-banner"; then
        output="PASS: Post-Login Banner is set"
    else
        output="FAIL: Post-Login Banner is not set (set post-login-banner missing in config system global)"
    fi
    echo "$output"
}

# 2.1.3 Ensure timezone is properly configured (Manual)
check_timezone_configuration() {
    local config_file="$1"
    local output=""
    if awk '/config system global/,/^end/' "$config_file" | grep -q "set timezone"; then
        output="PASS: Timezone is configured"
    else
        output="FAIL: Timezone is not configured (set timezone missing in config system global)"
    fi
    echo "$output"
}

# 2.1.4 Ensure correct system time is configured through NTP (Automated)
# 7.4.x: config system ntp with ntpsync enable
check_ntp_configuration() {
    local config_file="$1"
    local output=""
    if grep -q "config system ntp" "$config_file"; then
        if awk '/config system ntp/,/^end/' "$config_file" | grep -q "set ntpsync enable"; then
            output="PASS: NTP synchronization is enabled"
        else
            output="FAIL: NTP block found but ntpsync is not explicitly enabled"
        fi
    else
        output="FAIL: NTP is not configured (config system ntp block missing)"
    fi
    echo "$output"
}

# 2.1.5 Ensure hostname is set (Automated)
check_hostname_configuration() {
    local config_file="$1"
    local output=""
    if awk '/config system global/,/^end/' "$config_file" | grep -q "set hostname"; then
        output="PASS: Hostname is set"
    else
        output="FAIL: Hostname is not set (set hostname missing in config system global)"
    fi
    echo "$output"
}

# 2.1.6 Ensure the latest firmware is installed (Manual)
check_latest_firmware() {
    local output="MANUAL CHECK REQUIRED: Verify the latest FortiOS 7.4.x firmware is installed"
    echo "$output"
}

# 2.1.7 Disable USB Firmware and configuration installation (Automated)
# Fail only if explicitly enabled; absence = disabled (default)
check_usb_disable() {
    local config_file="$1"
    local output=""
    if awk '/config system global/,/^end/' "$config_file" | grep -q "set usb-auto-install enable"; then
        output="FAIL: USB auto-install is explicitly enabled"
    else
        output="PASS: USB auto-install is disabled (not explicitly enabled)"
    fi
    echo "$output"
}

# 2.1.8 Disable static keys for TLS (Automated)
# 7.4.x key: ssl-static-key-ciphers disable
check_tls_static_keys() {
    local config_file="$1"
    local output=""
    if awk '/config system global/,/^end/' "$config_file" | grep -q "set ssl-static-key-ciphers disable"; then
        output="PASS: Static key ciphers for TLS are disabled"
    else
        output="FAIL: Static key ciphers for TLS are not disabled (set ssl-static-key-ciphers disable missing)"
    fi
    echo "$output"
}

# 2.1.9 Enable Global Strong Encryption (Automated)
check_global_strong_encryption() {
    local config_file="$1"
    local output=""
    if awk '/config system global/,/^end/' "$config_file" | grep -q "set strong-crypto enable"; then
        output="PASS: Global Strong Encryption is enabled"
    else
        output="FAIL: Global Strong Encryption is not enabled (set strong-crypto enable missing)"
    fi
    echo "$output"
}

# 2.1.10 Ensure management GUI listens on secure TLS version (Automated)
# 7.4.x key: admin-https-ssl-versions should only include tlsv1-2/tlsv1-3
check_tls_version_management_gui() {
    local config_file="$1"
    local output=""
    if awk '/config system global/,/^end/' "$config_file" | grep -q "set admin-https-ssl-versions"; then
        local tls_line
        tls_line=$(awk '/config system global/,/^end/' "$config_file" | grep "set admin-https-ssl-versions")
        if echo "$tls_line" | grep -qE "tlsv1-0|tlsv1-1"; then
            output="FAIL: Management GUI TLS includes weak versions (tlsv1-0 or tlsv1-1 present): $tls_line"
        else
            output="PASS: Management GUI listens on TLS 1.2/1.3 only"
        fi
    else
        output="FAIL: admin-https-ssl-versions not configured (defaults may allow weak TLS)"
    fi
    echo "$output"
}

# 2.1.11 CDN enabled for improved GUI performance (Level 2 - informational only)
check_cdn_enabled() {
    local config_file="$1"
    local output=""
    if awk '/config system global/,/^end/' "$config_file" | grep -q "set gui-cdn-usage enable"; then
        output="PASS: CDN (gui-cdn-usage) is enabled"
    else
        output="INFO (Level 2): CDN (gui-cdn-usage) is not enabled - not a security control"
    fi
    echo "$output"
}

# 2.1.12 Ensure single CPU core overloaded event is logged (Automated)
# 7.4.x key: log-single-cpu-high enable
check_cpu_overloaded_event() {
    local config_file="$1"
    local output=""
    if awk '/config system global/,/^end/' "$config_file" | grep -q "set log-single-cpu-high enable"; then
        output="PASS: Single CPU core overload logging is enabled"
    else
        output="FAIL: Single CPU core overload logging not enabled (set log-single-cpu-high enable missing)"
    fi
    echo "$output"
}

# 2.2.1 Ensure Password Policy is enabled (Automated)
# CIS 7.4.x: minimum-length >= 14
check_password_policy() {
    local config_file="$1"
    local output=""
    if grep -q "config system password-policy" "$config_file"; then
        local status
        status=$(awk '/config system password-policy/,/^end/' "$config_file" | grep "set status" | awk '{print $NF}')
        local minlen
        minlen=$(awk '/config system password-policy/,/^end/' "$config_file" | grep "set minimum-length" | awk '{print $NF}')
        if echo "$status" | grep -q "enable"; then
            if [ -n "$minlen" ] && [ "$minlen" -ge 14 ] 2>/dev/null; then
                output="PASS: Password Policy is enabled with minimum-length $minlen (>=14)"
            else
                output="FAIL: Password Policy enabled but minimum-length is ${minlen:-not set} (CIS requires >=14)"
            fi
        else
            output="FAIL: Password Policy is not enabled"
        fi
    else
        output="FAIL: config system password-policy block not found"
    fi
    echo "$output"
}

# 2.2.2 Ensure admin password retries and lockout time configured (Automated)
# CIS 7.4.x: threshold <= 3, duration >= 900 seconds
check_password_retries_lockout() {
    local config_file="$1"
    local output=""
    local threshold duration
    threshold=$(awk '/config system global/,/^end/' "$config_file" | grep "set admin-lockout-threshold" | awk '{print $NF}')
    duration=$(awk '/config system global/,/^end/' "$config_file" | grep "set admin-lockout-duration" | awk '{print $NF}')
    if [ -n "$threshold" ] && [ -n "$duration" ]; then
        if [ "$threshold" -le 3 ] && [ "$duration" -ge 900 ] 2>/dev/null; then
            output="PASS: Admin lockout configured (threshold=$threshold retries, duration=${duration}s)"
        else
            output="FAIL: Admin lockout does not meet CIS requirements (threshold=$threshold should be <=3, duration=${duration}s should be >=900)"
        fi
    else
        output="FAIL: admin-lockout-threshold or admin-lockout-duration not configured (threshold=${threshold:-not set}, duration=${duration:-not set})"
    fi
    echo "$output"
}

# 2.3.1 Ensure only SNMPv3 is enabled (Automated)
check_snmpv3_only() {
    local config_file="$1"
    local output=""
    local v1_enabled v2_enabled
    v1_enabled=$(awk '/config system snmp community/,/^end/' "$config_file" | grep "set query-v1-status enable")
    v2_enabled=$(awk '/config system snmp community/,/^end/' "$config_file" | grep "set query-v2c-status enable")
    if [ -n "$v1_enabled" ] || [ -n "$v2_enabled" ]; then
        output="FAIL: SNMPv1 or SNMPv2c is still enabled (query-v1-status or query-v2c-status set to enable)"
    else
        output="PASS: SNMPv1 and SNMPv2c are not explicitly enabled"
    fi
    echo "$output"
}

# 2.3.2 Allow only trusted hosts in SNMPv3 (Manual)
check_snmpv3_trusted_hosts() {
    local output="MANUAL CHECK REQUIRED: Verify SNMPv3 user hosts are restricted to trusted IP ranges"
    echo "$output"
}

# 2.3.3 Ensure SNMP agent has description/contact/location (Manual)
check_snmp_agent_description() {
    local output="MANUAL CHECK REQUIRED: Verify SNMP sysinfo has description/contact/location set"
    echo "$output"
}

# 2.3.4 Enable SNMP trap for memory usage (Automated) - NEW in 7.4.x benchmark
# CIS: trap-free-memory-threshold >= 20, trap-freeable-memory-threshold <= 50
check_snmp_memory_trap() {
    local config_file="$1"
    local output=""
    local free_thresh freeable_thresh
    free_thresh=$(awk '/config system snmp sysinfo/,/^end/' "$config_file" | grep "set trap-free-memory-threshold" | awk '{print $NF}')
    freeable_thresh=$(awk '/config system snmp sysinfo/,/^end/' "$config_file" | grep "set trap-freeable-memory-threshold" | awk '{print $NF}')
    if [ -n "$free_thresh" ] && [ -n "$freeable_thresh" ]; then
        if [ "$free_thresh" -ge 20 ] && [ "$freeable_thresh" -le 50 ] 2>/dev/null; then
            output="PASS: SNMP memory trap configured (free-threshold=${free_thresh}%, freeable-threshold=${freeable_thresh}%)"
        else
            output="FAIL: SNMP memory trap thresholds do not meet CIS requirements (free=${free_thresh}% needs >=20, freeable=${freeable_thresh}% needs <=50)"
        fi
    else
        output="FAIL: SNMP memory trap thresholds not configured (trap-free-memory-threshold or trap-freeable-memory-threshold missing)"
    fi
    echo "$output"
}

# 2.4.1 Remove default admin user and create one with different name (Automated)
# UPDATED in 7.4.x: was "change default admin password", now requires removing the account
check_default_admin_removed() {
    local config_file="$1"
    local output=""
    if awk '/config system admin/,/^end/' "$config_file" | grep -q 'edit "admin"'; then
        output="FAIL: Default 'admin' account still exists - CIS 7.4.x requires removing it and creating a named account"
    else
        output="PASS: Default 'admin' account not found in configuration"
    fi
    echo "$output"
}

# 2.4.2 Ensure all login accounts have specific trusted hosts enabled (Automated)
check_login_accounts_trusted_hosts() {
    local config_file="$1"
    local output=""
    if awk '/config system admin/,/^end/' "$config_file" | grep -q "set trusthost"; then
        output="PASS: Admin trusted hosts are configured (verify all accounts have trusthost set)"
    else
        output="FAIL: No admin accounts appear to have trusted hosts configured"
    fi
    echo "$output"
}

# 2.4.3 Ensure admin accounts with different privileges have correct profiles (Manual)
check_admin_accounts_profiles() {
    local output="MANUAL CHECK REQUIRED: Verify all admin accounts have the correct access profile assigned"
    echo "$output"
}

# 2.4.4 Ensure Admin idle timeout time is configured (Automated)
# 7.4.x key: admintimeout (max 15 minutes per CIS)
check_idle_timeout() {
    local config_file="$1"
    local output=""
    local timeout
    timeout=$(awk '/config system global/,/^end/' "$config_file" | grep "set admintimeout" | awk '{print $NF}')
    if [ -n "$timeout" ]; then
        if [ "$timeout" -le 15 ] && [ "$timeout" -gt 0 ] 2>/dev/null; then
            output="PASS: Admin idle timeout is ${timeout} minutes (<= 15)"
        else
            output="FAIL: Admin idle timeout is ${timeout} minutes (CIS requires <= 15 minutes)"
        fi
    else
        output="FAIL: admintimeout not configured under config system global"
    fi
    echo "$output"
}

# 2.4.5 Ensure only encrypted access channels are enabled (Automated)
check_encrypted_access_channels() {
    local config_file="$1"
    local output=""
    if awk '/config system global/,/^end/' "$config_file" | grep -q "set admin-https-redirect disable"; then
        output="FAIL: HTTPS redirect is disabled - plain HTTP admin access may be reachable"
    else
        output="PASS: HTTPS redirect not disabled (encrypted admin access enforced)"
    fi
    echo "$output"
}

# 2.4.6 Apply Local-in Policies (Automated)
apply_local_in_policies() {
    local config_file="$1"
    local output=""
    if grep -q "config firewall local-in-policy" "$config_file"; then
        output="PASS: Local-in policy configuration block exists (review rules manually)"
    else
        output="FAIL: No local-in policy configuration found (config firewall local-in-policy missing)"
    fi
    echo "$output"
}

# 2.4.7 Ensure default Admin ports are changed (Automated)
check_default_admin_ports_changed() {
    local config_file="$1"
    local output=""
    local https_port http_port
    https_port=$(awk '/config system global/,/^end/' "$config_file" | grep "set admin-https-port" | awk '{print $NF}')
    http_port=$(awk '/config system global/,/^end/' "$config_file" | grep "set admin-http-port" | awk '{print $NF}')
    if [ "${https_port}" = "443" ] || [ "${http_port}" = "80" ]; then
        output="FAIL: Default admin ports still in use (HTTPS:${https_port:-443}, HTTP:${http_port:-80})"
    elif [ -n "$https_port" ]; then
        output="PASS: Admin HTTPS port changed to $https_port"
    else
        output="MANUAL CHECK REQUIRED: Could not determine admin port from config - verify default ports have been changed"
    fi
    echo "$output"
}

# 2.4.8 Virtual patching on the local-in management interface (Automated)
# 7.4.x: IPS sensor applied to local-in-policy
check_virtual_patching_local_in_interface() {
    local config_file="$1"
    local output=""
    if awk '/config firewall local-in-policy/,/^end/' "$config_file" | grep -q "set ips-sensor"; then
        output="PASS: IPS sensor (virtual patching) is applied to a local-in policy"
    else
        output="FAIL: No IPS sensor found on local-in policies (virtual patching not configured)"
    fi
    echo "$output"
}

# ---- Section 2.5: High Availability (renumbered from 2.4.9-11 in 7.0.x) ----

# 2.5.1 Ensure High Availability configuration is enabled (Manual)
check_ha_configuration() {
    local config_file="$1"
    local output=""
    if grep -q "config system ha" "$config_file"; then
        if awk '/config system ha/,/^end/' "$config_file" | grep -qE "set mode (a-a|a-p|active)"; then
            output="PASS: High Availability is configured"
        else
            output="MANUAL CHECK REQUIRED: HA block exists - verify mode is active-active or active-passive"
        fi
    else
        output="INFO: HA configuration not found - may be a standalone device"
    fi
    echo "$output"
}

# 2.5.2 Ensure Monitor Interfaces for HA devices is enabled (Automated)
check_ha_monitor_interfaces() {
    local config_file="$1"
    local output=""
    if awk '/config system ha/,/^end/' "$config_file" | grep -q "set monitor"; then
        output="PASS: HA interface monitoring is configured"
    else
        output="FAIL: HA interface monitoring not configured (set monitor missing in config system ha)"
    fi
    echo "$output"
}

# 2.5.3 Ensure HA Reserved Management Interface is configured (Automated)
check_ha_reserved_management_interface() {
    local config_file="$1"
    local output=""
    if awk '/config system ha/,/^end/' "$config_file" | grep -q "set reserved-mgmt-interface"; then
        output="PASS: HA Reserved Management Interface is configured"
    else
        output="FAIL: HA Reserved Management Interface not configured (set reserved-mgmt-interface missing)"
    fi
    echo "$output"
}

# ============================================================
# SECTION 3 - FIREWALL SETTINGS
# ============================================================

# 3.1 Ensure unused policies are reviewed regularly (Manual)
check_review_unused_policies() {
    local output="MANUAL CHECK REQUIRED: Review firewall policies and remove/disable unused ones (0 bytes or no Last Used date)"
    echo "$output"
}

# 3.2 Ensure policies do not use ALL as Service (Automated)
check_no_all_service_policies() {
    local config_file="$1"
    local output=""
    if awk '/config firewall policy/,/^end/' "$config_file" | grep -q 'set service "ALL"'; then
        output="FAIL: At least one firewall policy uses ALL as Service - restrict to required services"
    else
        output="PASS: No firewall policies found using ALL as Service"
    fi
    echo "$output"
}

# 3.3 Ensure firewall policy denying Tor/malicious/scanner IPs using ISDB (Automated)
check_denying_traffic_to_from_tor() {
    local config_file="$1"
    local output=""
    if awk '/config firewall policy/,/^end/' "$config_file" | grep -qi "isdb" && \
       awk '/config firewall policy/,/^end/' "$config_file" | grep -q "set action deny"; then
        output="PASS: ISDB-based deny policies appear configured (verify Tor/malicious/scanner entries manually)"
    else
        output="FAIL: No ISDB-based deny policy detected for Tor/malicious/scanner addresses"
    fi
    echo "$output"
}

# 3.4 Ensure logging is enabled on all firewall policies (Automated)
check_logging_enabled_firewall_policies() {
    local config_file="$1"
    local output=""
    local count
    count=$(awk '/config firewall policy/,/^end/' "$config_file" | grep -c "set logtraffic disable" 2>/dev/null || echo 0)
    if [ "$count" -gt 0 ]; then
        output="FAIL: $count firewall policy/policies have logging explicitly disabled"
    else
        output="PASS: No firewall policies found with logging disabled"
    fi
    echo "$output"
}

# ============================================================
# SECTION 4 - SYSTEM HARDENING
# ============================================================

# 4.1.1 Detect Botnet connections (Manual)
detect_botnet_connections() {
    local output="MANUAL CHECK REQUIRED: Verify botnet detection is enabled in IPS sensor applied to policies"
    echo "$output"
}

# 4.1.2 Apply IPS Security Profile to Policies (Automated)
apply_ips_security_profile() {
    local config_file="$1"
    local output=""
    if awk '/config firewall policy/,/^end/' "$config_file" | grep -q "set ips-sensor"; then
        output="PASS: IPS security profile is applied to at least one firewall policy"
    else
        output="FAIL: No IPS security profile found on firewall policies (set ips-sensor missing)"
    fi
    echo "$output"
}

# 4.2.1 Ensure Antivirus Definition Push Updates are Configured (Automated)
check_antivirus_definition_updates() {
    local config_file="$1"
    local output=""
    if awk '/config system autoupdate/,/^end/' "$config_file" | grep -q "set status enable"; then
        output="PASS: Antivirus/signature auto-update is enabled"
    else
        output="FAIL: Antivirus definition auto-update not confirmed enabled in config system autoupdate"
    fi
    echo "$output"
}

# 4.2.2 Apply Antivirus Security Profile to Policies (Manual)
apply_antivirus_security_profile() {
    local output="MANUAL CHECK REQUIRED: Verify an antivirus profile is applied to all relevant firewall policies"
    echo "$output"
}

# 4.2.3 Ensure Outbreak Prevention Database is enabled (Automated)
# 7.4.x: config antivirus settings / set outbreak-prevention enable
check_outbreak_prevention_database() {
    local config_file="$1"
    local output=""
    if grep -q "config antivirus settings" "$config_file"; then
        if awk '/config antivirus settings/,/^end/' "$config_file" | grep -q "set outbreak-prevention enable"; then
            output="PASS: Outbreak Prevention is enabled in antivirus settings"
        else
            output="FAIL: Outbreak Prevention not enabled (set outbreak-prevention enable missing in config antivirus settings)"
        fi
    else
        output="FAIL: config antivirus settings block not found"
    fi
    echo "$output"
}

# 4.2.4 Enable AI/heuristic based malware detection (Automated)
# 7.4.x: machine-learning-detection in antivirus profile
check_ai_malware_detection() {
    local config_file="$1"
    local output=""
    if grep -q "config antivirus profile" "$config_file"; then
        if awk '/config antivirus profile/,/^end/' "$config_file" | grep -q "set machine-learning-detection"; then
            output="PASS: AI/heuristic (machine-learning-detection) configured in antivirus profile"
        else
            output="FAIL: machine-learning-detection not found in antivirus profile(s)"
        fi
    else
        output="FAIL: No antivirus profile defined (config antivirus profile missing)"
    fi
    echo "$output"
}

# 4.2.5 Enable grayware detection on antivirus (Automated)
# 7.4.x: set grayware enable in antivirus profile
check_grayware_detection() {
    local config_file="$1"
    local output=""
    if grep -q "config antivirus profile" "$config_file"; then
        if awk '/config antivirus profile/,/^end/' "$config_file" | grep -q "set grayware enable"; then
            output="PASS: Grayware detection is enabled in an antivirus profile"
        else
            output="FAIL: Grayware detection not enabled in antivirus profile(s) (set grayware enable missing)"
        fi
    else
        output="FAIL: No antivirus profile defined (config antivirus profile missing)"
    fi
    echo "$output"
}

# 4.2.6 Ensure inline scanning with FortiGuard AI-Based Sandbox Service is enabled (Automated)
check_inline_scanning_sandbox() {
    local config_file="$1"
    local output=""
    if awk '/config antivirus profile/,/^end/' "$config_file" | grep -q "set analytics-bl-filetype\|set fortisandbox-mode\|set scan-mode full"; then
        output="PASS: Inline AI sandbox scanning configuration found in antivirus profile"
    else
        output="FAIL: Inline AI sandbox scanning not detected in antivirus profiles (verify FortiGuard AI sandbox enablement)"
    fi
    echo "$output"
}

# 4.3.1 Enable Botnet C&C Domain Blocking DNS Filter (Automated)
enable_botnet_cnc_domain_blocking() {
    local config_file="$1"
    local output=""
    if grep -q "config dnsfilter profile" "$config_file"; then
        if awk '/config dnsfilter profile/,/^end/' "$config_file" | grep -qE "set botnet-domains? block"; then
            output="PASS: Botnet C&C domain blocking is enabled in a DNS filter profile"
        else
            output="FAIL: Botnet C&C domain blocking not set to block in DNS filter profile(s)"
        fi
    else
        output="FAIL: No DNS filter profile defined (config dnsfilter profile missing)"
    fi
    echo "$output"
}

# 4.3.2 Ensure DNS Filter logs all DNS queries and responses (Automated)
check_dns_filter_logging() {
    local config_file="$1"
    local output=""
    if grep -q "config dnsfilter profile" "$config_file"; then
        if awk '/config dnsfilter profile/,/^end/' "$config_file" | grep -q "set log-all-domain enable"; then
            output="PASS: DNS filter is configured to log all DNS queries"
        else
            output="FAIL: DNS filter profile(s) do not have log-all-domain enable set"
        fi
    else
        output="FAIL: No DNS filter profile defined"
    fi
    echo "$output"
}

# 4.3.3 Apply DNS Filter Security Profile to Policies (Automated)
apply_dns_filter_security_profile() {
    local config_file="$1"
    local output=""
    if awk '/config firewall policy/,/^end/' "$config_file" | grep -q "set dnsfilter-profile"; then
        output="PASS: DNS filter security profile is applied to at least one firewall policy"
    else
        output="FAIL: No DNS filter profile found applied to firewall policies (set dnsfilter-profile missing)"
    fi
    echo "$output"
}

# 4.4.1 Create a Web Filtering Profile (Automated)
# UPDATED in 7.4.x: checks profile existence (was "block high risk categories")
check_web_filtering_profile() {
    local config_file="$1"
    local output=""
    if grep -q "config webfilter profile" "$config_file"; then
        output="PASS: A web filter profile exists (verify it is applied to policies and blocks high-risk categories)"
    else
        output="FAIL: No web filter profile defined (config webfilter profile missing)"
    fi
    echo "$output"
}

# 4.4.2 Block applications running on non-default ports (Automated)
block_non_default_port_applications() {
    local config_file="$1"
    local output=""
    if awk '/config application list/,/^end/' "$config_file" | grep -q "set enforce-default-app-port enable"; then
        output="PASS: Applications running on non-default ports are blocked (enforce-default-app-port enable)"
    else
        output="FAIL: Applications on non-default ports may not be blocked (enforce-default-app-port enable missing)"
    fi
    echo "$output"
}

# ---- Section 4.5: Application Control (renumbered from 4.4 in 7.0.x) ----

# 4.5.1 Block high risk categories on Application Control (Manual)
block_high_risk_categories() {
    local output="MANUAL CHECK REQUIRED: Verify Application Control profile blocks high-risk categories (P2P, proxy, etc.)"
    echo "$output"
}

# 4.5.3 Ensure all Application Control traffic is logged (Automated)
check_application_control_logging() {
    local config_file="$1"
    local output=""
    if grep -q "config application list" "$config_file"; then
        if awk '/config application list/,/^end/' "$config_file" | grep -qE "set other-application-log enable|set unknown-application-log enable"; then
            output="PASS: Application Control logging configured for other/unknown applications"
        else
            output="FAIL: Application Control logging for other/unknown apps not found"
        fi
    else
        output="FAIL: No application list profile defined (config application list missing)"
    fi
    echo "$output"
}

# 4.5.4 Apply Application Control Security Profile to Policies (Automated)
apply_application_control_security_profile() {
    local config_file="$1"
    local output=""
    if awk '/config firewall policy/,/^end/' "$config_file" | grep -q "set application-list"; then
        output="PASS: Application Control security profile is applied to at least one firewall policy"
    else
        output="FAIL: No Application Control profile found on firewall policies (set application-list missing)"
    fi
    echo "$output"
}

# ============================================================
# SECTION 5 - LOGGING AND MONITORING
# ============================================================

# 5.1.1 Enable Compromised Host Quarantine (Automated)
check_compromised_host_quarantine() {
    local config_file="$1"
    local output=""
    if grep -q "config user quarantine" "$config_file"; then
        output="PASS: Compromised Host Quarantine configuration block exists"
    else
        output="FAIL: Compromised Host Quarantine not configured (config user quarantine missing)"
    fi
    echo "$output"
}

# 5.2.1.1 Ensure Security Fabric is Configured (Automated)
check_security_fabric_configured() {
    local config_file="$1"
    local output=""
    if grep -q "config system csf" "$config_file"; then
        if awk '/config system csf/,/^end/' "$config_file" | grep -q "set status enable"; then
            output="PASS: Security Fabric (CSF) is enabled"
        else
            output="FAIL: Security Fabric block exists but status is not enabled"
        fi
    else
        output="FAIL: Security Fabric not configured (config system csf missing)"
    fi
    echo "$output"
}

# ============================================================
# SECTION 6 - COMMUNICATION AND TRAFFIC MANAGEMENT
# ============================================================

# 6.1.1 Apply a Trusted Signed Certificate for VPN Portal (Automated)
apply_trusted_certificate_vpn_portal() {
    local config_file="$1"
    local output=""
    if awk '/config vpn ssl settings/,/^end/' "$config_file" | grep -q "set servercert"; then
        local cert
        cert=$(awk '/config vpn ssl settings/,/^end/' "$config_file" | grep "set servercert" | awk '{print $NF}')
        if echo "$cert" | grep -qi "self\|Fortinet_Factory\|Fortinet_CA"; then
            output="FAIL: VPN portal uses self-signed or factory certificate ($cert) - replace with trusted CA-signed cert"
        else
            output="PASS: VPN portal certificate is set to: $cert (verify it is a trusted CA-signed cert)"
        fi
    else
        output="MANUAL CHECK REQUIRED: VPN SSL settings not found or servercert not configured"
    fi
    echo "$output"
}

# 6.1.2 Enable Limited TLS Versions for SSL VPN (Automated)
check_ssl_vpn_tls_versions() {
    local config_file="$1"
    local output=""
    if awk '/config vpn ssl settings/,/^end/' "$config_file" | grep -q "set ssl-min-proto-ver"; then
        local min_ver
        min_ver=$(awk '/config vpn ssl settings/,/^end/' "$config_file" | grep "set ssl-min-proto-ver" | awk '{print $NF}')
        if echo "$min_ver" | grep -qE "tls1-2|tls1-3"; then
            output="PASS: SSL VPN minimum TLS version is $min_ver"
        else
            output="FAIL: SSL VPN minimum TLS version is $min_ver (must be tls1-2 or higher)"
        fi
    else
        output="FAIL: ssl-min-proto-ver not configured in VPN SSL settings"
    fi
    echo "$output"
}

# ============================================================
# SECTION 7 - AUDITING, ACCOUNTABILITY, AND RISK MANAGEMENT
# ============================================================

# 7.1.1 Enable Event Logging (Automated)
check_event_logging_enabled() {
    local config_file="$1"
    local output=""
    if grep -q "config log setting" "$config_file"; then
        if awk '/config log setting/,/^end/' "$config_file" | grep -qE "set fwpolicy-implicit-log enable|set local-in-allow enable|set local-in-deny-unicast enable"; then
            output="PASS: Event logging is configured in config log setting"
        else
            output="FAIL: Event logging options not fully configured (review config log setting)"
        fi
    else
        output="FAIL: config log setting block not found"
    fi
    echo "$output"
}

# 7.2.1 Encrypt Logs Sent to FortiAnalyzer / FortiManager (Automated)
encrypt_logs_sent_to_forti() {
    local config_file="$1"
    local output=""
    if grep -q "config log fortianalyzer" "$config_file"; then
        if awk '/config log fortianalyzer/,/^end/' "$config_file" | grep -q "set enc-algorithm"; then
            output="PASS: FortiAnalyzer log encryption algorithm is configured"
        else
            output="FAIL: FortiAnalyzer log encryption not configured (set enc-algorithm missing)"
        fi
    else
        output="INFO: config log fortianalyzer not found - FortiAnalyzer may not be in use"
    fi
    echo "$output"
}

# 7.3.1 Encrypt Log Transmission to FortiAnalyzer / FortiManager (Automated)
enable_log_transmission_to_forti() {
    local config_file="$1"
    local output=""
    if grep -q "config log fortianalyzer" "$config_file"; then
        if awk '/config log fortianalyzer/,/^end/' "$config_file" | grep -q "set status enable"; then
            output="PASS: Log transmission to FortiAnalyzer is enabled"
        else
            output="FAIL: Log transmission to FortiAnalyzer not enabled (set status enable missing)"
        fi
    else
        output="INFO: FortiAnalyzer log transmission not configured"
    fi
    echo "$output"
}

# 7.3.2 Encrypt Log Transmission to Syslog (Automated) - NEW in 7.4.x benchmark
check_syslog_encryption() {
    local config_file="$1"
    local output=""
    if grep -q "config log syslogd" "$config_file"; then
        if awk '/config log syslogd/,/^end/' "$config_file" | grep -qE "set enc-algorithm|set mode reliable"; then
            output="PASS: Syslog transmission uses encryption or reliable (TLS) mode"
        else
            output="FAIL: Syslog transmission encryption not configured (set mode reliable and/or enc-algorithm missing)"
        fi
    else
        output="FAIL: Syslog (config log syslogd) not configured"
    fi
    echo "$output"
}

# 7.3.3 Centralized Logging and Reporting (Automated)
check_centralized_logging_reporting() {
    local config_file="$1"
    local output=""
    local forti_enabled syslog_enabled
    forti_enabled=$(awk '/config log fortianalyzer/,/^end/' "$config_file" | grep "set status enable" | head -1)
    syslog_enabled=$(awk '/config log syslogd/,/^end/' "$config_file" | grep "set status enable" | head -1)
    if [ -n "$forti_enabled" ] || [ -n "$syslog_enabled" ]; then
        output="PASS: Centralized log transmission is enabled (FortiAnalyzer or syslog)"
    else
        output="FAIL: No centralized log destination is enabled (FortiAnalyzer and syslog both disabled or unconfigured)"
    fi
    echo "$output"
}

# ============================================================
# MAIN ENTRY POINT
# ============================================================

if [ $# -ne 1 ]; then
    echo "Usage: $0 <fortigate_config_file>"
    exit 1
fi

config_file="$1"

if [ ! -f "$config_file" ]; then
    echo "ERROR: Config file '$config_file' not found."
    exit 1
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
HTML_FILE="FORTIGATE_7.4.x_CIS_BENCHMARK_v1.0.1_AUDIT_${TIMESTAMP}.html"
CSV_FILE="/tmp/fg_audit_$$.csv"

echo "Section,CheckID,Description,Type,Result" > "$CSV_FILE"

echo "====== CIS FortiGate 7.4.x Benchmark v1.0.1 Audit Started ======"
echo "Auditing config: $config_file"

# Helper: run check, write structured CSV row, log result
# Usage: run_check "Section Name" "CheckID" "Description" "Automated|Manual" function [args...]
run_check() {
    local section="$1"
    local check_id="$2"
    local description="$3"
    local type="$4"
    local func="$5"
    shift 5
    local result
    result=$("$func" "$@" 2>/dev/null | head -1)
    # Write to CSV - escape any commas in result
    local safe_result="${result//,/;}"
    printf '"%s","%s","%s","%s","%s"\n' \
        "$section" "$check_id" "$description" "$type" "$safe_result" >> "$CSV_FILE"
    log "[$check_id] $result"
}

# ---- Section 1: Network Settings ----
run_check "1 - Network Settings"         "1.1"     "Ensure DNS server is configured"                                           "Automated" check_dns_configuration         "$config_file"
run_check "1 - Network Settings"         "1.2"     "Ensure intra-zone traffic is not always allowed"                           "Automated" check_intra_zone_traffic         "$config_file"
run_check "1 - Network Settings"         "1.3"     "Disable all management related services on WAN port"                       "Automated" check_wan_management_services    "$config_file"

# ---- Section 2.1: System Settings ----
run_check "2.1 - System Settings"        "2.1.1"   "Ensure Pre-Login Banner is set"                                            "Automated" check_pre_login_banner           "$config_file"
run_check "2.1 - System Settings"        "2.1.2"   "Ensure Post-Login Banner is set"                                           "Automated" check_post_login_banner          "$config_file"
run_check "2.1 - System Settings"        "2.1.3"   "Ensure timezone is properly configured"                                    "Manual"    check_timezone_configuration      "$config_file"
run_check "2.1 - System Settings"        "2.1.4"   "Ensure correct system time configured through NTP"                         "Automated" check_ntp_configuration          "$config_file"
run_check "2.1 - System Settings"        "2.1.5"   "Ensure hostname is set"                                                    "Automated" check_hostname_configuration      "$config_file"
run_check "2.1 - System Settings"        "2.1.6"   "Ensure latest firmware is installed"                                       "Manual"    check_latest_firmware
run_check "2.1 - System Settings"        "2.1.7"   "Disable USB Firmware and configuration installation"                       "Automated" check_usb_disable                "$config_file"
run_check "2.1 - System Settings"        "2.1.8"   "Disable static keys for TLS"                                               "Automated" check_tls_static_keys            "$config_file"
run_check "2.1 - System Settings"        "2.1.9"   "Enable Global Strong Encryption"                                           "Automated" check_global_strong_encryption   "$config_file"
run_check "2.1 - System Settings"        "2.1.10"  "Ensure management GUI listens on secure TLS version"                       "Automated" check_tls_version_management_gui "$config_file"
run_check "2.1 - System Settings"        "2.1.11"  "Ensure CDN is enabled for improved GUI performance"                        "Level 2"   check_cdn_enabled                "$config_file"
run_check "2.1 - System Settings"        "2.1.12"  "Ensure single CPU core overloaded event is logged"                         "Automated" check_cpu_overloaded_event       "$config_file"

# ---- Section 2.2: Password Settings ----
run_check "2.2 - Password Settings"      "2.2.1"   "Ensure Password Policy is enabled"                                         "Automated" check_password_policy            "$config_file"
run_check "2.2 - Password Settings"      "2.2.2"   "Ensure admin password retries and lockout time are configured"             "Automated" check_password_retries_lockout   "$config_file"

# ---- Section 2.3: SNMP Settings ----
run_check "2.3 - SNMP Settings"          "2.3.1"   "Ensure only SNMPv3 is enabled"                                             "Automated" check_snmpv3_only               "$config_file"
run_check "2.3 - SNMP Settings"          "2.3.2"   "Allow only trusted hosts in SNMPv3"                                        "Manual"    check_snmpv3_trusted_hosts
run_check "2.3 - SNMP Settings"          "2.3.3"   "Ensure SNMP agent has description/contact/location set"                    "Manual"    check_snmp_agent_description
run_check "2.3 - SNMP Settings"          "2.3.4"   "Enable SNMP trap for memory usage"                                         "Automated" check_snmp_memory_trap           "$config_file"

# ---- Section 2.4: User Authentication ----
run_check "2.4 - User Authentication"    "2.4.1"   "Remove default admin user and create one with different name"              "Automated" check_default_admin_removed      "$config_file"
run_check "2.4 - User Authentication"    "2.4.2"   "Ensure all login accounts have specific trusted hosts enabled"             "Automated" check_login_accounts_trusted_hosts "$config_file"
run_check "2.4 - User Authentication"    "2.4.3"   "Ensure admin accounts with different privileges have correct profiles"     "Manual"    check_admin_accounts_profiles
run_check "2.4 - User Authentication"    "2.4.4"   "Ensure Admin idle timeout time is configured"                              "Automated" check_idle_timeout               "$config_file"
run_check "2.4 - User Authentication"    "2.4.5"   "Ensure only encrypted access channels are enabled"                         "Automated" check_encrypted_access_channels  "$config_file"
run_check "2.4 - User Authentication"    "2.4.6"   "Apply Local-in Policies"                                                   "Automated" apply_local_in_policies          "$config_file"
run_check "2.4 - User Authentication"    "2.4.7"   "Ensure default Admin ports are changed"                                    "Automated" check_default_admin_ports_changed "$config_file"
run_check "2.4 - User Authentication"    "2.4.8"   "Virtual patching on the local-in management interface"                     "Automated" check_virtual_patching_local_in_interface "$config_file"

# ---- Section 2.5: High Availability ----
run_check "2.5 - High Availability"      "2.5.1"   "Ensure High Availability configuration is enabled"                         "Manual"    check_ha_configuration           "$config_file"
run_check "2.5 - High Availability"      "2.5.2"   "Ensure Monitor Interfaces for HA devices is enabled"                       "Automated" check_ha_monitor_interfaces      "$config_file"
run_check "2.5 - High Availability"      "2.5.3"   "Ensure HA Reserved Management Interface is configured"                     "Automated" check_ha_reserved_management_interface "$config_file"

# ---- Section 3: Firewall Settings ----
run_check "3 - Firewall Settings"        "3.1"     "Ensure unused policies are reviewed regularly"                             "Manual"    check_review_unused_policies
run_check "3 - Firewall Settings"        "3.2"     "Ensure that policies do not use ALL as Service"                            "Automated" check_no_all_service_policies    "$config_file"
run_check "3 - Firewall Settings"        "3.3"     "Ensure firewall policy denying Tor/malicious/scanner IPs via ISDB"         "Automated" check_denying_traffic_to_from_tor "$config_file"
run_check "3 - Firewall Settings"        "3.4"     "Ensure logging is enabled on all firewall policies"                        "Automated" check_logging_enabled_firewall_policies "$config_file"

# ---- Section 4.1: Malware Prevention ----
run_check "4.1 - Malware Prevention"     "4.1.1"   "Detect Botnet connections"                                                 "Manual"    detect_botnet_connections
run_check "4.1 - Malware Prevention"     "4.1.2"   "Apply IPS Security Profile to Policies"                                   "Automated" apply_ips_security_profile       "$config_file"

# ---- Section 4.2: Antivirus & Anti-Spyware ----
run_check "4.2 - Antivirus"              "4.2.1"   "Ensure Antivirus Definition Push Updates are Configured"                   "Automated" check_antivirus_definition_updates "$config_file"
run_check "4.2 - Antivirus"              "4.2.2"   "Apply Antivirus Security Profile to Policies"                             "Manual"    apply_antivirus_security_profile
run_check "4.2 - Antivirus"              "4.2.3"   "Ensure Outbreak Prevention Database is enabled"                           "Automated" check_outbreak_prevention_database "$config_file"
run_check "4.2 - Antivirus"              "4.2.4"   "Enable AI/heuristic based malware detection"                              "Automated" check_ai_malware_detection        "$config_file"
run_check "4.2 - Antivirus"              "4.2.5"   "Enable grayware detection on antivirus"                                   "Automated" check_grayware_detection          "$config_file"
run_check "4.2 - Antivirus"              "4.2.6"   "Ensure inline scanning with FortiGuard AI-Based Sandbox is enabled"       "Automated" check_inline_scanning_sandbox     "$config_file"

# ---- Section 4.3: DNS Filter ----
run_check "4.3 - DNS Filter"             "4.3.1"   "Enable Botnet C&C Domain Blocking DNS Filter"                             "Automated" enable_botnet_cnc_domain_blocking "$config_file"
run_check "4.3 - DNS Filter"             "4.3.2"   "Ensure DNS Filter logs all DNS queries and responses"                     "Automated" check_dns_filter_logging          "$config_file"
run_check "4.3 - DNS Filter"             "4.3.3"   "Apply DNS Filter Security Profile to Policies"                            "Automated" apply_dns_filter_security_profile  "$config_file"

# ---- Section 4.4: Web Filter ----
run_check "4.4 - Web Filter"             "4.4.1"   "Create a Web Filtering Profile"                                            "Automated" check_web_filtering_profile       "$config_file"
run_check "4.4 - Web Filter"             "4.4.2"   "Block applications running on non-default ports"                           "Automated" block_non_default_port_applications "$config_file"

# ---- Section 4.5: Application Control ----
run_check "4.5 - Application Control"    "4.5.1"   "Block high risk categories on Application Control"                        "Manual"    block_high_risk_categories
run_check "4.5 - Application Control"    "4.5.3"   "Ensure all Application Control related traffic is logged"                 "Automated" check_application_control_logging  "$config_file"
run_check "4.5 - Application Control"    "4.5.4"   "Apply Application Control Security Profile to Policies"                   "Automated" apply_application_control_security_profile "$config_file"

# ---- Section 5: Logging and Monitoring ----
run_check "5 - Logging & Monitoring"     "5.1.1"   "Enable Compromised Host Quarantine"                                        "Automated" check_compromised_host_quarantine "$config_file"
run_check "5 - Logging & Monitoring"     "5.2.1.1" "Ensure Security Fabric is Configured"                                     "Automated" check_security_fabric_configured  "$config_file"

# ---- Section 6: Communication & Traffic Management ----
run_check "6 - Communication & Traffic"  "6.1.1"   "Apply a Trusted Signed Certificate for VPN Portal"                        "Automated" apply_trusted_certificate_vpn_portal "$config_file"
run_check "6 - Communication & Traffic"  "6.1.2"   "Enable Limited TLS Versions for SSL VPN"                                  "Automated" check_ssl_vpn_tls_versions        "$config_file"

# ---- Section 7: Auditing, Accountability & Risk Management ----
run_check "7 - Auditing & Logging"       "7.1.1"   "Enable Event Logging"                                                      "Automated" check_event_logging_enabled       "$config_file"
run_check "7 - Auditing & Logging"       "7.2.1"   "Encrypt Logs Sent to FortiAnalyzer / FortiManager"                        "Automated" encrypt_logs_sent_to_forti        "$config_file"
run_check "7 - Auditing & Logging"       "7.3.1"   "Encrypt Log Transmission to FortiAnalyzer / FortiManager"                 "Automated" enable_log_transmission_to_forti  "$config_file"
run_check "7 - Auditing & Logging"       "7.3.2"   "Encrypt Log Transmission to Syslog"                                        "Automated" check_syslog_encryption           "$config_file"
run_check "7 - Auditing & Logging"       "7.3.3"   "Centralized Logging and Reporting"                                         "Automated" check_centralized_logging_reporting "$config_file"

echo "====== CIS FortiGate 7.4.x Benchmark v1.0.1 Audit Completed ======"

# ============================================================
# CALCULATE TOTALS
# ============================================================
total_checks=$(( $(wc -l < "$CSV_FILE") - 1 ))
total_pass=$(grep -c ',"PASS'   "$CSV_FILE" 2>/dev/null || true)
total_fail=$(grep -c ',"FAIL'   "$CSV_FILE" 2>/dev/null || true)
total_manual=$(grep -c ',"MANUAL' "$CSV_FILE" 2>/dev/null || true)
total_info=$(grep -c ',"INFO'   "$CSV_FILE" 2>/dev/null || true)


# Build a lookup of section -> list of rows for the section headers
cat > "$HTML_FILE" <<HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>FortiGate 7.4.x CIS Benchmark v1.0.1 Audit Report</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body  { font-family: 'Segoe UI', Arial, sans-serif; background: #f0f2f5; color: #222; padding: 24px; }
  h1    { color: #c8102e; margin-bottom: 4px; font-size: 1.6em; }
  .meta { color: #555; margin-bottom: 22px; font-size: .88em; }
  /* ---- Summary cards ---- */
  .summary { display: flex; gap: 20px; flex-wrap: wrap; margin-bottom: 28px; }
  .stat { background: #fff; border-radius: 8px; padding: 16px 28px;
          box-shadow: 0 2px 6px rgba(0,0,0,.1); text-align: center; min-width: 120px; }
  .stat .num   { font-size: 2.4em; font-weight: 700; }
  .stat .label { font-size: .75em; text-transform: uppercase; letter-spacing: .06em; color: #666; margin-top: 2px; }
  .s-total .num  { color: #1a1a2e; }
  .s-pass  .num  { color: #2d8a4e; }
  .s-fail  .num  { color: #c8102e; }
  .s-manual .num { color: #d97706; }
  .s-info  .num  { color: #4a6fa5; }
  /* ---- Section header bar (red, like Check Point) ---- */
  .section-header {
    background: #c8102e; color: #fff;
    padding: 9px 16px; font-weight: 600; font-size: .95em;
    margin: 20px 0 0; border-radius: 6px 6px 0 0;
    letter-spacing: .03em;
  }
  /* ---- Table ---- */
  table  { width: 100%; border-collapse: collapse; background: #fff;
           box-shadow: 0 2px 6px rgba(0,0,0,.08); margin-bottom: 4px; }
  th     { background: #2c2c54; color: #fff; padding: 9px 14px;
           text-align: left; font-size: .82em; font-weight: 600; }
  td     { padding: 8px 14px; border-bottom: 1px solid #eee;
           font-size: .84em; vertical-align: top; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: #f7f7fb; }
  /* ---- Row number ---- */
  td.row-num { color: #999; font-size: .78em; width: 36px; text-align: center; }
  /* ---- Check ID ---- */
  td.check-id { font-weight: 600; white-space: nowrap; width: 150px; }
  td.check-desc { white-space: nowrap; width: 450px; }
  /* ---- Result colours ---- */
  .r-PASS   { color: #2d8a4e; font-weight: 600; }
  .r-FAIL   { color: #c8102e; font-weight: 600; }
  .r-MANUAL { color: #d97706; font-weight: 600; }
  .r-INFO   { color: #4a6fa5; font-style: italic; }
  footer { margin-top: 32px; text-align: center; font-size: .76em; color: #aaa; }
</style>
</head>
<body>

<h1>&#x1F6E1; CIS FortiGate 7.4.x Benchmark v1.0.1 &ndash; Audit Report</h1>
<div class="meta">
  Config file audited: <strong>$(basename "$config_file")</strong> &nbsp;|&nbsp;
  Generated: $(date) &nbsp;|&nbsp;
  Benchmark: CIS FortiGate 7.4.x v1.0.1
</div>

<div class="summary">
  <div class="stat s-total"><div class="num">${total_checks}</div><div class="label">Total Checks</div></div>
  <div class="stat s-pass" ><div class="num">${total_pass}</div><div class="label">Pass</div></div>
  <div class="stat s-fail" ><div class="num">${total_fail}</div><div class="label">Fail</div></div>
  <div class="stat s-manual"><div class="num">${total_manual}</div><div class="label">Manual Review</div></div>
  <div class="stat s-info" ><div class="num">${total_info}</div><div class="label">Informational</div></div>
</div>

HTMLEOF

# ---- Parse CSV and emit section-grouped HTML table rows ----
current_section=""
row=0

while IFS= read -r line; do
    # Skip CSV header row
    echo "$line" | grep -q "^\"Section\"\|^Section," && continue

    # Extract fields (strip surrounding quotes)
    section=$(echo  "$line" | awk -F'","' '{print $1}' | tr -d '"')
    check_id=$(echo "$line" | awk -F'","' '{print $2}' | tr -d '"')
    desc=$(echo     "$line" | awk -F'","' '{print $3}' | tr -d '"')
    type=$(echo     "$line" | awk -F'","' '{print $4}' | tr -d '"')
    result=$(echo   "$line" | awk -F'","' '{print $5}' | tr -d '"')

    # Determine result CSS class
    if echo "$result" | grep -q "^PASS"; then
        cls="PASS"
    elif echo "$result" | grep -q "^FAIL"; then
        cls="FAIL"
    elif echo "$result" | grep -qE "^MANUAL|^INFO.*Level 2"; then
        cls="MANUAL"
    else
        cls="INFO"
    fi

    # Emit section header when section changes
    if [ "$section" != "$current_section" ]; then
        if [ -n "$current_section" ]; then
            # Close previous table
            echo "</table>" >> "$HTML_FILE"
        fi
        # New section header + table open
        printf '<div class="section-header">%s</div>\n' "$section" >> "$HTML_FILE"
        printf '<table>\n<tr><th>#</th><th>Check ID</th><th>Description / CIS Benchmark</th><th>Result</th></tr>\n' >> "$HTML_FILE"
        current_section="$section"
    fi

    row=$(( row + 1 ))
    printf '<tr><td class="row-num">%s</td><td class="check-id">%s</td><td class="check-desc">%s</td><td class="r-%s">%s</td></tr>\n' \
        "$row" "$check_id" "$desc" "$cls" "$result" >> "$HTML_FILE"

done < "$CSV_FILE"

# Close final table
cat >> "$HTML_FILE" <<HTMLEOF
</table>

<footer>
  CIS FortiGate 7.4.x Benchmark v1.0.1 &bull;
  Audit script: fortigate_cis_audit_74x.sh &bull;
  Checks marked Manual require verification directly on the FortiGate device or GUI
</footer>
</body>
</html>
HTMLEOF

# ============================================================
# CONSOLE SUMMARY
# ============================================================
echo ""
echo "============================================================"
echo "  CIS FortiGate 7.4.x v1.0.1 Audit Complete"
echo "  Total Checks  : $total_checks"
echo "  PASS          : $total_pass"
echo "  FAIL          : $total_fail"
echo "  Manual/Review : $total_manual"
echo "  Informational : $total_info"
echo "  HTML : $HTML_FILE"
echo "============================================================"
rm -f "$CSV_FILE"

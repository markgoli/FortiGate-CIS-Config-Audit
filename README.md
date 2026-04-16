# FortiGate Firewall CIS Benchmark Audit Script (v1.0.1) -- 7.4.x Series

This project provides an automated audit tool for reviewing **FortiGate
Firewall (7.4.x series)** configurations against the **Center for
Internet Security (CIS) Benchmark v1.0.1**.

The script parses exported configuration files and evaluates them
against CIS-recommended security controls, helping identify
misconfigurations and strengthen firewall security posture.

------------------------------------------------------------------------

## Features

-   Automated CIS Benchmark compliance checks (v1.0.1)
-   Tailored for FortiGate 7.4.x series
-   Supports parsing various types of configuration files (`.txt`, `.conf`)
-   Detects misconfigurations and security gaps
-   ⚡ Lightweight and fast (pure Bash implementation)
-   Enhances audit readiness and compliance posture

------------------------------------------------------------------------

## Requirements

-   Linux/Unix-based system
-   Bash shell (v4+ recommended)
-   Exported FortiGate configuration file\
    (e.g., from `show full-configuration`)

------------------------------------------------------------------------

## Usage

### 1. Make the script executable

``` bash
chmod +x fortigate_cis_audit_7_4_x.sh
```

### 2. Run the audit

``` bash
./fortigate_cis_audit_7_4_x.sh Forticonfig-Latest.txt
```

------------------------------------------------------------------------

## Input

The script expects a configuration file exported from a Check Point
Firewall. Configuration file formats can be:

-   `.txt`
-   `.conf`

Ensure the file contains complete and properly exported configuration
data for accurate analysis.


------------------------------------------------------------------------

## Output

The script generates 2 structured compliance reports (`.html`, `.csv`)  that:

-   Indicates **PASS / FAIL / REVIEW** per CIS control
-   Highlights insecure or non-compliant configurations
-   Provides context for what is recommended based on CIS Benchmarks.

------------------------------------------------------------------------

## CIS Benchmark Coverage

Aligned with:

-   **CIS FortiGate Firewall Benchmark v1.0.1 (7.4.x series)**

Coverage may include:

-   Administrative access controls
-   Password and authentication policies
-   Logging and monitoring settings
-   Network and firewall policy configurations
-   Secure management and system settings

------------------------------------------------------------------------

## Disclaimer

This script is intended for **security auditing and assessment purposes
only**.

-   It does **not** modify firewall configurations
-   Results should be reviewed by qualified personnel
-   Ensure proper authorization before auditing systems

------------------------------------------------------------------------

## 👨‍💻 Author

`Goli Mark Wasswa`


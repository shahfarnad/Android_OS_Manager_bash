# Android OS Manager (Linux Bash Simulation)

A menu-driven **Android Operating System Manager** built in GNU Bash on Ubuntu Linux. Because Android runs directly on top of a modified Linux kernel, this project demonstrates how core mobile OS operations—application sandboxing, background process execution, permission enforcement, and resource diagnostics—map directly to standard POSIX file operations, process signals, and Linux kernel utilities.

---

## Key Features

- **APK Installation & Sandboxing:** Simulates package installation by dynamically generating isolated app directories (`~/AndroidSystem/data/app/<AppName>`), package manifests, and executable run scripts.
- **Background Process Execution:** Launches installed apps as true asynchronous Linux background processes (`&`) and assigns custom process identifiers via `exec -a AndroidApp_<Name>` while tracking live Process IDs (`$!`).
- **Task Manager & Signal Control:** Inspects the active kernel process table (`ps -ef`, `grep`, `awk`) to list running Android PIDs and sends `SIGKILL` (`kill -9`) to simulate Android's **Force Stop** functionality.
- **OS-Level App Permissions:** Enforces access control by toggling Unix file permission modes between **Unlocked (`chmod 755`)** and **Locked (`chmod 444`)**, blocking execution when read-only bits are set.
- **Device Care Diagnostics:** Queries real-time volatile RAM/Swap allocation (`free -h`) and non-volatile filesystem storage (`df -h`) from the Linux host.
- **System Auditing (`logcat`):** Records chronological, timestamped system events (`boot`, `install`, `launch`, `kill`, `permission changes`) to `system.log` and displays recent entries via `tail`.

---

## Operating System Concepts Demonstrated

| OS Concept | Linux Implementation |
| :--- | :--- |
| **Process Creation & Naming** | `bash -c "exec -a AndroidApp_<Name> ... &"`, `$!` |
| **Process Monitoring & Signals** | `ps -ef`, `pgrep -f`, `pkill -f`, `kill -9` (`SIGKILL`) |
| **Access Control & Security** | `chmod 755`, `chmod 444`, `[ -x "$file" ]` inode checks |
| **File System Hierarchy** | `mkdir -p`, `rm -rf`, isolated `/data/app` sandbox structure |
| **Memory & Storage Profiling** | `free -h` (`/proc/meminfo`), `df -h` |
| **I/O Redirection & Logging** | `2>/dev/null` (`stderr` suppression), `>>`, `date`, `tail -n 10` |

---

## Project Structure

```text
Android_OS_Manager_bash/
├── Android_Manager.sh        # Main interactive Bash application
├── README.md                 # Project documentation
└── LICENSE                   # MIT License

# Runtime Workspace (Auto-generated on first launch)
~/AndroidSystem/
├── data/
│   └── app/
│       └── <AppName>/
│           ├── manifest.txt  # Simulated package metadata
│           └── run.sh        # Background daemon script
└── system.log                # Timestamped OS event log

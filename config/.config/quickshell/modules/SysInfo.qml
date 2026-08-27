import QtQuick
import Quickshell.Io

// waybar's cpu and memory modules, both polled every 2s and both opening btop
// on click.
//
// waybar computed these itself; here they come from /proc directly. CPU usage
// is a delta between samples - /proc/stat counts cumulative jiffies since
// boot, so a single read tells you the average since power-on, which is not
// what anyone means by "CPU:12%".
BarText {
    leftPadding: 10
    rightPadding: 10
    id: root

    property string kind: "cpu"  // "cpu" or "memory"
    property int usage: 0

    text: (kind === "cpu" ? "CPU:" : "RAM:") + usage + "%"
    onLeft: () => btop.running = true

    Process {
        id: btop
        command: ["kitty", "-e", "btop"]
    }

    property int lastIdle: 0
    property int lastTotal: 0

    FileView {
        id: stat
        path: root.kind === "cpu" ? "/proc/stat" : "/proc/meminfo"
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            const text = stat.text();
            if (!text)
                return;

            if (root.kind === "cpu") {
                // user nice system idle iowait irq softirq steal
                const f = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
                const idle = f[3] + f[4];
                const total = f.reduce((a, b) => a + b, 0);
                const dIdle = idle - root.lastIdle;
                const dTotal = total - root.lastTotal;
                root.lastIdle = idle;
                root.lastTotal = total;
                if (dTotal > 0)
                    root.usage = Math.round(100 * (dTotal - dIdle) / dTotal);
            } else {
                // MemAvailable, not MemFree: free excludes cache and page
                // buffers, which would report this machine as ~90% used at
                // idle and make the number meaningless.
                const get = key => {
                    const m = text.match(new RegExp("^" + key + ":\\s+(\\d+)", "m"));
                    return m ? Number(m[1]) : 0;
                };
                const total = get("MemTotal");
                const avail = get("MemAvailable");
                if (total > 0)
                    root.usage = Math.round(100 * (total - avail) / total);
            }
        }
    }
}

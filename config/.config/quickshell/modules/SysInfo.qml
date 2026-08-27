import QtQuick
import Quickshell.Io

// waybar's cpu and memory modules: polled every 2s from /proc, both opening
// btop on click. CPU usage is a delta between samples - /proc/stat counts
// cumulative jiffies since boot, so a single read gives the average since
// power-on, not what "CPU:12%" means.
BarText {
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
                // Only the aggregate "cpu" line matters; slicing it off first
                // skips parsing the ~20 per-core lines below it.
                const f = text.slice(0, text.indexOf("\n")).trim()
                    .split(/\s+/).slice(1).map(Number);
                const idle = f[3] + f[4];
                const total = f.reduce((a, b) => a + b, 0);
                const dIdle = idle - root.lastIdle;
                const dTotal = total - root.lastTotal;
                root.lastIdle = idle;
                root.lastTotal = total;
                if (dTotal > 0)
                    root.usage = Math.round(100 * (dTotal - dIdle) / dTotal);
            } else {
                // MemAvailable, not MemFree: free excludes cache/buffers,
                // which reports ~90% used at idle.
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

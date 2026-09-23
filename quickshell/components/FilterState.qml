import QtQuick
import "../services" as Services
Item {
    id: state
    property bool selMoved: false
    signal refilterRequested()
    function schedule(): void {
        state.selMoved = false;
        refilterTimer.restart();
    }
    function flush(): void {
        if (refilterTimer.running) {
            refilterTimer.stop();
            state.refilterRequested();
        }
    }
    function keptIndex(currentKey: string, out: var): int {
        if (state.selMoved && currentKey !== "") {
            const idx = out.findIndex(e => (e.key ?? "") === currentKey);
            if (idx >= 0)
                return idx;
        }
        return 0;
    }
    Timer {
        id: refilterTimer
        interval: Services.Theme.refilterDelay
        repeat: false
        onTriggered: state.refilterRequested()
    }
}

import QtQuick
import Quickshell
import Quickshell.Services.Pam
Scope {
    id: root
    signal unlocked()
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property string authMessage: ""
    property int failedAttempts: 0
    onCurrentTextChanged: {
        showFailure = false;
        authMessage = "";
    }
    function tryUnlock(): void {
        if (currentText === "" || unlockInProgress || lockout.running)
            return;
        unlockInProgress = true;
        pam.start();
    }
    Timer {
        id: lockout
        interval: 1000
        repeat: false
    }
    function clearAuth(): void {
        currentText = "";
        showFailure = false;
        authMessage = "";
        unlockInProgress = false;
    }
    function reset(): void {
        if (pam.active)
            pam.abort();
        root.clearAuth();
    }
    PamContext {
        id: pam
        onPamMessage: {
            if (responseRequired)
                respond(root.currentText);
            else if (messageIsError)
                root.authMessage = message;
        }
        onError: error => {
            root.currentText = "";
            root.authMessage = "Auth error: " + error;
            root.unlockInProgress = false;
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.failedAttempts = 0;
                root.clearAuth();
                root.unlocked();
            } else if (root.authMessage === "") {
                root.currentText = "";
                root.showFailure = true;
                root.failedAttempts += 1;
                if (root.failedAttempts >= 5)
                    lockout.restart();
            } else {
                root.currentText = "";
            }
            root.unlockInProgress = false;
        }
    }
}

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
    onCurrentTextChanged: {
        showFailure = false;
        authMessage = "";
    }
    function tryUnlock(): void {
        if (currentText === "" || unlockInProgress)
            return;
        unlockInProgress = true;
        pam.start();
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
            root.authMessage = "Auth error: " + error;
            root.unlockInProgress = false;
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.clearAuth();
                root.unlocked();
            } else if (root.authMessage === "") {
                root.currentText = "";
                root.showFailure = true;
            }
            root.unlockInProgress = false;
        }
    }
}

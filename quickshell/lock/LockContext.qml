import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Shared auth state for all lock surfaces (one per monitor).
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

    function reset(): void {
        if (pam.active)
            pam.abort();
        currentText = "";
        showFailure = false;
        authMessage = "";
        unlockInProgress = false;
    }

    PamContext {
        id: pam

        // System "login" stack (same as hyprlock's include): a custom
        // config dir breaks pam_unix's setuid helper, so stay here.

        // pam_unix asks for the password via a response request.
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

        // Wrong passwords arrive as Failure; a set authMessage
        // (see onError) means the stack itself broke, keep it.
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.currentText = "";
                root.unlocked();
            } else if (root.authMessage === "") {
                root.currentText = "";
                root.showFailure = true;
            }

            root.unlockInProgress = false;
        }
    }
}

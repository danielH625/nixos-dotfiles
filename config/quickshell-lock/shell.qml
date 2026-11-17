import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

ShellRoot {
    id: root
    // Never hot-reload an active lock. Preview.qml remains independently reloadable.
    settings.watchFiles: false
    Preferences { id: prefs }
    NotchGeometry { id: notchGeometry }
    property real entryNotchWidth: prefs.idleWidth
    property real exitNotchWidth: prefs.idleWidth
    function currentNotchWidth() {
        return notchGeometry.width > 0 ? notchGeometry.width : prefs.idleWidth;
    }
    property bool initialized: false
    property url activeWallpaper: ""
    property url preparedWallpaper: Quickshell.env("QS_LOCK_WALLPAPER") || prefs.wallpaper
    property bool lockRequested: false
    function requestLock(wallpaper) {
        if (session.locked || lockRequested) return;
        authenticated = false;
        exiting = false;
        failed = false;
        awaitingResponse = false;
        retry.stop();
        clearFields();
        message = "Enter your password";
        lockRequested = true;
        if (wallpaper) preparedWallpaper = wallpaper;
        preloadTimeout.restart();
        checkWallpaper();
    }
    IpcHandler {
        target: "lock"
        function lock(wallpaper: string): void { root.requestLock(wallpaper); }
        // Refresh the preloaded image without changing a live lock.
        function prepare(wallpaper: string): void {
            if (!session.locked && !root.lockRequested && wallpaper)
                root.preparedWallpaper = wallpaper;
        }
        function stop(): void {
            if (!session.locked && !root.lockRequested && !root.requestInProgress)
                Qt.quit();
        }
        function status(): string {
            return session.secure ? "locked" : root.lockRequested ? "locking" : "ready";
        }
    }
    function beginLock(useWallpaper) {
        if (!initialized || !lockRequested || session.locked) return;
        preloadTimeout.stop();
        activeWallpaper = useWallpaper ? preparedWallpaper : "";
        entryNotchWidth = currentNotchWidth();
        exitNotchWidth = entryNotchWidth;
        session.locked = true;
    }
    function checkWallpaper() {
        if (wallpaperPreload.status === Image.Ready) beginLock(true);
        else if (wallpaperPreload.status === Image.Error || wallpaperPreload.status === Image.Null)
            beginLock(false);
    }
    Image {
        id: wallpaperPreload
        visible: false
        source: root.preparedWallpaper
        asynchronous: true
        cache: true
        onStatusChanged: root.checkWallpaper()
    }
    // A broken/slow image must not postpone locking indefinitely. On timeout,
    // use a solid background for this lock attempt instead of popping in later.
    Timer {
        id: preloadTimeout
        interval: 1200
        onTriggered: {
            console.warn("Wallpaper preparation timed out; locking with solid background");
            root.beginLock(false);
        }
    }
    property bool authenticated: false
    property bool exiting: false
    property bool failed: false
    property bool requestInProgress: false
    property bool awaitingResponse: false
    property bool pendingReady: false
    property string pendingResponse: ""
    property string message: "Enter your password"
    readonly property bool canEnter: session.secure && !authenticated && !retry.running
        && (!requestInProgress || awaitingResponse)
    readonly property bool waiting: requestInProgress && !awaitingResponse
    signal clearFields()

    function answerPending() {
        if (!pendingReady || !pam.responseRequired) return;
        const response = pendingResponse;
        pendingResponse = "";
        pendingReady = false;
        awaitingResponse = false;
        pam.respond(response);
    }
    function submit(response) {
        if (!canEnter || response.length === 0) return;
        failed = false;
        clearFields();
        message = "Checking…";
        if (requestInProgress && awaitingResponse && pam.responseRequired) {
            awaitingResponse = false;
            pam.respond(response);
            return;
        }
        pendingResponse = response;
        pendingReady = true;
        requestInProgress = true;
        if (!pam.start()) {
            pendingResponse = "";
            pendingReady = false;
            requestInProgress = false;
            failed = true;
            message = "Authentication unavailable — try again";
            retry.restart();
        } else {
            answerPending();
        }
    }
    Timer { id: retry; interval: 200 }
    PamContext {
        id: pam
        config: "quickshell-lock"
        onPamMessage: {
            if (responseRequired) {
                if (root.pendingReady) root.answerPending();
                else {
                    root.awaitingResponse = true;
                    root.message = message || "Authentication response required";
                }
            }
        }
        onCompleted: function(result) {
            root.pendingResponse = "";
            root.pendingReady = false;
            // Keep input gated until old fields are cleared and the result is handled.
            root.awaitingResponse = false;
            root.clearFields();
            if (result === PamResult.Success) {
                root.authenticated = true;
                root.message = "Unlocked";
                root.exitNotchWidth = root.currentNotchWidth();
                root.exiting = true;
                releaseLock.start();
            } else {
                root.failed = true;
                root.message = result === PamResult.Error
                    ? "Authentication unavailable — check PAM configuration"
                    : "Password not accepted — try again";
                retry.restart();
            }
            root.requestInProgress = false;
        }
    }
    WlSessionLock {
        id: session
        locked: false
        onSecureChanged: if (secure) console.info("LOCK_SECURE: all outputs covered")
        WlSessionLockSurface {
            color: "#1d2021"
            LockView {
                id: view
                anchors.fill: parent
                theme: prefs
                restingWidth: root.exiting ? root.exitNotchWidth : root.entryNotchWidth
                wallpaperSource: root.activeWallpaper
                expanded: session.secure && !root.exiting
                acceptingInput: root.canEnter
                busy: root.waiting || root.authenticated
                failed: root.failed
                message: root.message
                onSubmitted: function(response) { root.submit(response); }
                onEditing: { if (root.canEnter) root.failed = false; }
                Connections {
                    target: root
                    function onClearFields() { view.clearInput(); }
                }
            }
        }
    }
    Timer {
        id: releaseLock
        interval: prefs.animationDuration + 80
        onTriggered: {
            // The only unlock path. No unlock IPC, keybind, timeout, or cancel button.
            if (!root.authenticated) return;
            session.locked = false;
            root.lockRequested = false;
            root.clearFields();
            root.pendingResponse = "";
            root.pendingReady = false;
            // Stay alive with the wallpaper cache ready for the next lock.
            root.authenticated = false;
            root.exiting = false;
            root.failed = false;
        }
    }
    Component.onCompleted: {
        initialized = true;
        if (Quickshell.env("QS_LOCK_START") === "1")
            requestLock(preparedWallpaper);
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

// Visual component only. No authentication or session-lock authority lives here.
Item {
    id: root
    required property var theme
    property real restingWidth: theme.idleWidth
    property url wallpaperSource: theme.wallpaper
    property bool expanded: false
    property bool acceptingInput: true
    property bool busy: false
    property bool failed: false
    property bool preview: false
    property string message: "Enter your password"
    property date now: new Date()
    property real progress: expanded ? 1 : 0
    signal submitted(string response)
    signal editing()

    function clearInput() { password.text = ""; }
    function focusInput() { password.forceActiveFocus(); }
    function submit() {
        if (!acceptingInput || busy || progress < 0.95 || password.text.length === 0) return;
        const response = password.text;
        password.text = "";
        root.submitted(response);
    }
    onAcceptingInputChanged: if (acceptingInput) password.forceActiveFocus()
    onExpandedChanged: if (expanded) password.forceActiveFocus()
    Component.onCompleted: password.forceActiveFocus()

    Behavior on progress {
        NumberAnimation { duration: root.theme.animationDuration; easing.type: Easing.InOutCubic }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // Always opaque: the desktop is never visible through this component.
    Rectangle { anchors.fill: parent; color: "#1d2021" }
    Image {
        anchors.fill: parent
        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        // The real lock preloads this exact URL before requesting lock surfaces.
        // Same URL and decode size allow every output to reuse the cached image.
        asynchronous: false
        cache: true
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.theme.dimAmount * root.progress
    }
    MouseArea { anchors.fill: parent; onClicked: root.focusInput() }

    Item {
        id: notch
        objectName: "passwordPill"
        readonly property real diameter: 48
        readonly property real maximumWidth: Math.max(diameter, Math.min(480, root.width - 32))
        readonly property int maximumDots: Math.max(1, Math.floor((maximumWidth - 30 + 6) / 12))
        readonly property int dotCount: Math.min(password.length, maximumDots)
        readonly property real dotsWidth: dotCount > 0 ? dotCount * 12 - 6 : 0
        property real typedWidth: Math.max(diameter, dotsWidth + 30)
        Behavior on typedWidth {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        readonly property real fl: (root.theme.island ? 0 : root.theme.flare) * (1 - root.progress)
        readonly property real bodyWidth: Math.min(root.width - 2 * fl - 24,
            root.restingWidth * (1 - root.progress) + typedWidth * root.progress)
        x: (root.width - width) / 2
        y: root.theme.topGap * (1 - root.progress) + 12 * root.progress
        width: bodyWidth + fl * 2
        height: Math.max(24, root.theme.bandHeight - root.theme.topGap) * (1 - root.progress)
            + diameter * root.progress
        // readonly property real restingRadius: Math.max(0, Math.min(root.theme.roundness, height - fl - 1))
        readonly property real restingRadius: Math.max(0, Math.min(
            root.theme.roundness,
            root.theme.island ? height / 2 : height - fl - 1
        ))
        readonly property real rb: restingRadius * (1 - root.progress) + height / 2 * root.progress
        readonly property real rt: (root.theme.island ? Math.min(root.theme.roundness, height / 2) : 0)
            * (1 - root.progress) + height / 2 * root.progress

        // One contour morphs from the resting notch into a detached circle/pill.
        Shape {
            anchors.fill: parent
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                id: path
                readonly property real fl: notch.fl
                readonly property real rb: notch.rb
                readonly property real rt: notch.rt
                readonly property real w: notch.bodyWidth
                readonly property real h: notch.height
                readonly property real k: 0.55228475
                readonly property real ik: 1 - k
                strokeColor: "transparent"
                strokeWidth: 0
                fillColor: root.theme.notchColor
                startX: rt; startY: 0
                PathCubic { control1X: path.rt * path.ik + path.fl * path.k; control1Y: 0; control2X: path.fl; control2Y: (path.fl + path.rt) * path.ik; x: path.fl; y: path.fl + path.rt }
                PathLine { x: path.fl; y: path.h - path.rb }
                PathCubic { control1X: path.fl; control1Y: path.h - path.rb * path.ik; control2X: path.fl + path.rb * path.ik; control2Y: path.h; x: path.fl + path.rb; y: path.h }
                PathLine { x: path.fl + path.w - path.rb; y: path.h }
                PathCubic { control1X: path.fl + path.w - path.rb * path.ik; control1Y: path.h; control2X: path.fl + path.w; control2Y: path.h - path.rb * path.ik; x: path.fl + path.w; y: path.h - path.rb }
                PathLine { x: path.fl + path.w; y: path.fl + path.rt }
                PathCubic { control1X: path.fl + path.w; control1Y: (path.fl + path.rt) * path.ik; control2X: path.fl + path.w + path.fl * path.k - path.rt * path.ik; control2Y: 0; x: path.fl + path.w + path.fl - path.rt; y: 0 }
                PathLine { x: path.rt; y: 0 }
            }
        }

        Item {
            anchors { fill: parent; leftMargin: 15; rightMargin: 15 }
            clip: true
            Row {
                anchors.centerIn: parent
                spacing: 0
                opacity: Math.max(0, (root.progress - 0.35) / 0.65)
                Item {
                    objectName: "lockIcon"
                    visible: password.length === 0
                    width: 18
                    height: 22
                    // Font-independent lock icon: no Nerd Font glyph dependency.
                    Rectangle {
                        x: 4; y: 1
                        width: 10; height: 12; radius: 5
                        color: "transparent"
                        border.width: 2
                        border.color: root.failed ? root.theme.errorColor : "white"
                    }
                    Rectangle {
                        x: 1; y: 9
                        width: 16; height: 12; radius: 3
                        color: root.failed ? root.theme.errorColor : "white"
                        Rectangle {
                            anchors.centerIn: parent
                            width: 2; height: 4; radius: 1
                            color: "black"
                        }
                    }
                }
                Item {
                    width: notch.dotsWidth
                    height: 22
                    visible: notch.dotCount > 0
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Repeater {
                            model: notch.dotCount
                            Rectangle { width: 6; height: 6; radius: 3; color: "white" }
                        }
                    }
                }
            }
        }

        // Focusable input remains invisible; only the custom white dots are drawn.
        TextInput {
            id: password
            objectName: "passwordField"
            anchors.fill: parent
            opacity: 0
            echoMode: TextInput.Password
            passwordCharacter: "•"
            passwordMaskDelay: 0
            cursorVisible: false
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhHiddenText
            maximumLength: 1024
            readOnly: !root.acceptingInput || root.busy
            selectByMouse: false
            focus: true
            onAccepted: root.submit()
            onTextEdited: root.editing()
            Keys.onEscapePressed: root.clearInput()
            Accessible.name: "Password"
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: root.focusInput()
        }
    }

    // No persistent label, border, textbox, or submit arrow. Enter submits.
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: notch.bottom; topMargin: 12 }
        width: Math.max(0, root.width - 32)
        horizontalAlignment: Text.AlignHCenter
        text: root.message
        textFormat: Text.PlainText
        color: root.failed ? root.theme.errorColor : root.theme.muted
        font.family: root.theme.fontFamily
        font.pixelSize: 12
        elide: Text.ElideRight
        opacity: root.progress
        visible: root.failed || root.busy
    }

    Text {
        id: clock
        objectName: "movingClock"
        readonly property real startCenter: root.theme.topGap + Math.max(24, root.theme.bandHeight - root.theme.topGap) / 2
        readonly property real finalSize: Math.min(144, root.width * 0.16, root.height * 0.20)
        x: (root.width - width) / 2
        y: startCenter + (root.height * 0.48 - startCenter) * root.progress - height / 2
        text: Qt.formatDateTime(root.now, "HH:mm")
        color: root.theme.foreground
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.clockSize + (finalSize - root.theme.clockSize) * root.progress
        font.weight: Font.DemiBold
        font.features: ({ "tnum": 1 })
        renderType: Text.CurveRendering
    }
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: clock.bottom; topMargin: 10 }
        text: Qt.formatDateTime(root.now, "dddd, MMMM d")
        color: root.theme.foreground
        font.family: root.theme.fontFamily
        font.pixelSize: Math.min(20, root.width * 0.025)
        opacity: Math.max(0, (root.progress - 0.55) / 0.45) * 0.85
    }
}

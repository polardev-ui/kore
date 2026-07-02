import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: splash
    width: 1920
    height: 1080
    color: "#0a0a0c"

    property int stage: 0

    Item {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height

        Image {
            id: logo
            source: "images/kore-logo.png"
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -80
            width: 256
            height: 256
            sourceSize.width: 256
            sourceSize.height: 256
            fillMode: Image.PreserveAspectFit
            smooth: true

            opacity: 0
            SequentialAnimation {
                running: true
                PauseAnimation { duration: 200 }
                NumberAnimation {
                    target: logo
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 800
                    easing.type: Easing.InOutCubic
                }
            }
        }

        Text {
            id: title
            text: "Kore OS"
            font {
                family: "JetBrains Mono"
                pixelSize: 24
                weight: Font.Bold
            }
            color: "#d4d4d8"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom
            anchors.topMargin: 24
            opacity: 0

            SequentialAnimation {
                running: true
                PauseAnimation { duration: 600 }
                NumberAnimation {
                    target: title
                    property: "opacity"
                    from: 0
                    to: 0.8
                    duration: 600
                    easing.type: Easing.InOutCubic
                }
            }
        }

        Text {
            id: subtitle
            text: "Minimal · Clean · Secure"
            font {
                family: "JetBrains Mono"
                pixelSize: 13
            }
            color: "#52525b"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: title.bottom
            anchors.topMargin: 8
            opacity: 0

            SequentialAnimation {
                running: true
                PauseAnimation { duration: 800 }
                NumberAnimation {
                    target: subtitle
                    property: "opacity"
                    from: 0
                    to: 0.6
                    duration: 600
                    easing.type: Easing.InOutCubic
                }
            }
        }

        Rectangle {
            id: progressBar
            width: 0
            height: 3
            radius: 1.5
            color: "#3d7cf5"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: subtitle.bottom
            anchors.topMargin: 40

            Behavior on width {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            width: 200
            height: 3
            radius: 1.5
            color: "#1a1a1f"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: subtitle.bottom
            anchors.topMargin: 40
        }
    }

    Rectangle {
        id: footer
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: parent.width
        height: 40
        color: "transparent"

        Text {
            anchors.centerIn: parent
            text: "© Josh Clark · wsgpolar.me"
            font {
                family: "JetBrains Mono"
                pixelSize: 11
            }
            color: "#3f3f46"
            opacity: 0

            SequentialAnimation {
                running: true
                PauseAnimation { duration: 1200 }
                NumberAnimation {
                    target: footer
                    property: "opacity"
                    from: 0
                    to: 0.5
                    duration: 500
                    easing.type: Easing.InOutCubic
                }
            }
        }
    }

    SequentialAnimation {
        running: true
        loops: Animation.Infinite

        NumberAnimation {
            target: progressBar
            property: "width"
            from: 0
            to: 200
            duration: 1500
            easing.type: Easing.InOutQuad
        }

        PauseAnimation { duration: 200 }

        NumberAnimation {
            target: progressBar
            property: "width"
            from: 200
            to: 0
            duration: 1500
            easing.type: Easing.InOutQuad
        }

        PauseAnimation { duration: 200 }
    }
}

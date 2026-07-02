import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#0a0a0c"

    property string backgroundSource: "/usr/share/backgrounds/kore/korebackground.png"

    Image {
        id: backgroundImage
        source: backgroundSource
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        opacity: 0.3
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0a0c"
        opacity: 0.5
    }

    Item {
        anchors.centerIn: parent
        width: 400
        height: childrenRect.height

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24

            Image {
                id: logo
                source: "/usr/share/plymouth/themes/kore/logo.png"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 96
                Layout.preferredHeight: 96
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Text {
                text: "Kore OS"
                font {
                    family: "JetBrains Mono"
                    pixelSize: 28
                    weight: Font.Bold
                }
                color: "#ffffff"
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.9
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#3f3f46"
                opacity: 0.3
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                TextField {
                    id: usernameField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    placeholderText: "Username"
                    font {
                        family: "JetBrains Mono"
                        pixelSize: 13
                    }
                    color: "#e4e4e7"
                    placeholderTextColor: "#52525b"
                    background: Rectangle {
                        radius: 6
                        color: "#18181b"
                        border {
                            color: usernameField.activeFocus ? "#3d7cf5" : "#27272a"
                            width: 1
                        }
                    }
                    leftPadding: 12
                }

                TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    placeholderText: "Password"
                    font {
                        family: "JetBrains Mono"
                        pixelSize: 13
                    }
                    color: "#e4e4e7"
                    placeholderTextColor: "#52525b"
                    echoMode: TextInput.Password
                    background: Rectangle {
                        radius: 6
                        color: "#18181b"
                        border {
                            color: passwordField.activeFocus ? "#3d7cf5" : "#27272a"
                            width: 1
                        }
                    }
                    leftPadding: 12
                }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    text: "Sign In"
                    font {
                        family: "JetBrains Mono"
                        pixelSize: 13
                        weight: Font.Medium
                    }

                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        color: parent.hovered ? "#4d8cf7" : "#3d7cf5"
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    onClicked: {
                        /* Placeholder: SDDM handles authentication */
                    }
                }
            }

            Text {
                text: "© Josh Clark · wsgpolar.me"
                font {
                    family: "JetBrains Mono"
                    pixelSize: 10
                }
                color: "#3f3f46"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 24
                opacity: 0.6
            }

            Text {
                text: "Minimal · Clean · Secure"
                font {
                    family: "JetBrains Mono"
                    pixelSize: 11
                }
                color: "#52525b"
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.5
            }
        }
    }

    Item {
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        height: 48

        RowLayout {
            anchors {
                left: parent.left
                bottom: parent.bottom
                leftMargin: 24
                bottomMargin: 16
            }
            spacing: 16

            Text {
                text: "Session: Plasma (Wayland)"
                font {
                    family: "JetBrains Mono"
                    pixelSize: 11
                }
                color: "#3f3f46"
            }
        }

        RowLayout {
            anchors {
                right: parent.right
                bottom: parent.bottom
                rightMargin: 24
                bottomMargin: 16
            }
            spacing: 16

            Text {
                text: "Kore OS"
                font {
                    family: "JetBrains Mono"
                    pixelSize: 11
                }
                color: "#3f3f46"
            }
        }
    }
}

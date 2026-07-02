import QtQuick 2.15
import QtQuick.Controls 2.15

SlideShow {
    id: slideshow
    width: 800
    height: 500

    property int currentSlide: 0
    property int totalSlides: 5

    Image {
        source: "squid.png"
        anchors.centerIn: parent
        width: 128
        height: 128
        fillMode: Image.PreserveAspectFit
    }

    Text {
        id: title
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.verticalCenter
            topMargin: 20
        }
        text: "Kore OS"
        font {
            family: "JetBrains Mono"
            pixelSize: 32
            weight: Font.Bold
        }
        color: "#e4e4e7"
    }

    Text {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: title.bottom
            topMargin: 12
        }
        text: "Minimal · Clean · Secure"
        font {
            family: "JetBrains Mono"
            pixelSize: 16
        }
        color: "#71717a"
    }

    Text {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 30
        }
        text: "Created by Josh Clark\nhttps://wsgpolar.me"
        font {
            family: "JetBrains Mono"
            pixelSize: 12
        }
        color: "#52525b"
        horizontalAlignment: Text.AlignHCenter
    }
}

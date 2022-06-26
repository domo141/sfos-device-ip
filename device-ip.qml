// -*- css -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.2 // for executing process

// SPDX-License-Identifier: BSD 2-Clause "Simplified" License

ApplicationWindow {
    cover: Component {
        CoverBackground {
            Label {
                text: "Device IP"
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                anchors.top: parent.top
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Label {
                anchors.centerIn: parent
                text: pageStack.currentPage.ipv4s
                fontSizeMode: Text.HorizontalWidth
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
    initialPage: Component {
        Page {
            id: page
            property string ipv4s
            PageHeader {
               id: header
               width: parent.width
               title: "Device IP"
            }
            MouseArea {
                width: page.width
                anchors.top: page.top
                anchors.bottom: texxt.top
                onClicked: python.device_ip_call()
            }
            Label {
                id: texxt // when this was 'text' it did not work... :/
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: header.bottom
                text: ""
                font.family: "Courier New"
                //textFormat: Text.styledText
                //fontSizeMode: Text.HorizontalWidth // does not wrok here...
                font.pixelSize: 40 // FIXME
                //Component.onCompleted: { python.device_ip_call() }
            }
            Python {
                id: python
                Component.onCompleted: {
                    //console.log("where does this go ?")
                    addImportPath(Qt.resolvedUrl('.'))
                    setHandler('update', function(text, ipv4s) {
                        texxt.text = text
                        page.ipv4s = ipv4s
                    })
                    importNames('device-ip', ['device_ip_call'], function() {})
                    python.device_ip_call()
                }
                function device_ip_call() {
                    call('device_ip_call', [], function() {})
                }
            }
        }
    }
}

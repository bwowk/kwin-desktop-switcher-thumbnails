/********************************************************************
 KWin - the KDE window manager
 This file is part of the KDE project.

Copyright (C) 2012, 2013 Martin Gräßlin <mgraesslin@kde.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************/
import QtQuick 2.0;
import QtQuick.Window 2.0;
import org.kde.plasma.core 2.0 as PlasmaCore;
import org.kde.plasma.components 2.0 as Plasma;
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons;
import org.kde.kwin 2.0 as KWinComponents;

PlasmaCore.Dialog {
    id: dialog
    location: PlasmaCore.Types.Floating
    visible: false
    flags: Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint
    outputOnly: true

    mainItem: Item {
        function loadConfig() {
            dialogItem.animationDuration = KWin.readConfig("PopupHideDelay", 1000);
            if (KWin.readConfig("TextOnly", "false") == "true") {
                dialogItem.showGrid = false;
            } else {
                dialogItem.showGrid = true;
            }
        }

        function show() {
            if (dialogItem.currentDesktop == workspace.currentDesktop - 1) {
                return;
            }
            dialogItem.previousDesktop = dialogItem.currentDesktop;
            timer.stop();
            dialogItem.currentDesktop = workspace.currentDesktop - 1;
            textElement.text = workspace.desktopName(workspace.currentDesktop);
            // screen geometry might have changed
            var screen = workspace.clientArea(KWin.FullScreenArea, workspace.activeScreen, workspace.currentDesktop);
            dialogItem.screenWidth = screen.width;
            dialogItem.screenHeight = screen.height;
            if (dialogItem.showGrid) {
                // non dependable properties might have changed
                view.columns = workspace.desktopGridWidth;
                view.rows = workspace.desktopGridHeight;
            }
            dialog.visible = true;
            // position might have changed
            dialog.x = screen.x + screen.width/2 - dialogItem.width/2;
            dialog.y = screen.y + screen.height/2 - dialogItem.height/2;
            // start the hide timer
            timer.start();
        }

        id: dialogItem
        property int screenWidth: 0
        property int screenHeight: 0
        // we count desktops starting from 0 to have it better match the layout in the Grid
        property int currentDesktop: 0
        property int previousDesktop: 0
        property int animationDuration: 1000
        property bool showGrid: true

        width: dialogItem.showGrid ? view.itemWidth * view.columns : textElement.width
        height: dialogItem.showGrid ? view.itemHeight * view.rows + textElement.height : textElement.height

        Plasma.Label {
            id: textElement
            anchors.top: dialogItem.showGrid ? parent.top : undefined
            anchors.horizontalCenter: parent.horizontalCenter
            text: workspace.desktopName(workspace.currentDesktop)
        }
        Grid {
            id: view
            columns: 1
            rows: 1
            visible: dialogItem.showGrid
            property int itemWidth: dialogItem.screenWidth * Math.min(0.8/columns, 0.1)
            property int itemHeight: Math.min(itemWidth * (dialogItem.screenHeight / dialogItem.screenWidth), dialogItem.screenHeight * Math.min(0.8/rows, 0.1))
            anchors {
                top: textElement.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            
            Repeater {
                id: repeater
                model: workspace.desktops
                Item {
                    width: view.itemWidth
                    height: view.itemHeight
                    KWinComponents.DesktopThumbnailItem {
                        anchors.fill: parent
                        desktop: index + 1
                        parent: null
                    }
                }
            }
            PlasmaCore.FrameSvgItem {
                id: activeElement
                anchors.fill: repeater.itemAt(dialogItem.previousDesktop)
                imagePath: "widgets/pager"
                prefix: "active"
                opacity: 0.25
                transitions: Transition {
                    // smoothly reanchor myRect and move into new position
                    AnchorAnimation { duration: dialogItem.animationDuration/2 }
                }
            }
            states: State {
                name: "reanchored"
                AnchorChanges {
                    target: activeElement
                    anchors.fill: repeater.itemAt(dialogItem.currentDesktop) }
            }
            Component.onCompleted: activeElement.state = "reanchored"
        }

        Timer {
            id: timer
            repeat: false
            interval: dialogItem.animationDuration
            onTriggered: dialog.visible = false
        }

        Connections {
            target: workspace
            onCurrentDesktopChanged: dialogItem.show()
            onNumberDesktopsChanged: {
                repeater.model = workspace.desktops;
            }
        }
        Connections {
            target: options
            onConfigChanged: dialogItem.loadConfig()
        }
        Component.onCompleted: {
            view.columns = workspace.desktopGridWidth;
            view.rows = workspace.desktopGridHeight;
            dialogItem.loadConfig();
            dialogItem.show();
        }
    }

    Component.onCompleted: {
        KWin.registerWindow(dialog);
    }
}

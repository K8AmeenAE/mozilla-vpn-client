/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import QtQuick 2.5
import QtQuick.Controls
import QtQuick.Layouts 1.14

import Mozilla.Shared 1.0
import Mozilla.VPN 1.0
import components.forms 0.1
import components 0.1

ColumnLayout {
    id: appListContainer
    objectName: "appListContainer"
    property string searchBarPlaceholder: ""
    readonly property string telemetryScreenId : "app_exclusions"
    property int availableHeight: 0;

    spacing: MZTheme.theme.vSpacing
    Layout.preferredWidth: parent.width

    Component {
        id: appListHeader

    ColumnLayout {
            id: appListHeaderColumn
            property var getProxyModel: searchBarWrapper.getProxyModel

            spacing: MZTheme.theme.vSpacingSmall
            width: applist.width - (3 * MZTheme.theme.windowMargin)

            MZSearchBar {
                property bool sorted: false;
                id: searchBarWrapper
                _filterProxySource: VPNAppPermissions
                _filterProxyCallback: obj => {
                    const filterValue = getSearchBarText();
                    return obj.appName.toLowerCase().includes(filterValue);
                }
                _searchBarHasError: applist.count === 0
                _searchBarPlaceholderText: searchBarPlaceholder
                Layout.fillWidth: true
            }

            MZLinkButton {
                property int numDisabledApps: MZSettings.vpnDisabledApps.length

                id: clearAllButton
                objectName: "clearAll"

                Layout.alignment: Qt.AlignLeft

                // Hack to horizontally align the text
                // with column of checkboxes.
                Layout.leftMargin: -4

                textAlignment: Text.AlignLeft
                labelText: MZI18n.SettingsAppExclusionClearAllApps
                fontSize: MZTheme.theme.fontSize
                fontName: MZTheme.theme.fontInterSemiBoldFamily

                onClicked: {
                    Glean.interaction.clearAppExclusionsSelected.record({screen:telemetryScreenId});
                    VPNAppPermissions.protectAll();
                }
                enabled: MZSettings.vpnDisabledApps.length > 0
                visible: applist.count > 0
            }

            MZVerticalSpacer {
                height: MZTheme.theme.dividerHeight
            }
        }
    }

    ListView {
        id: applist

        objectName: "appList"
        model: headerItem.getProxyModel()
        height: availableHeight // $TODO: Can this be replaced by layout values in https://doc.qt.io/qt-6/qml-qtquick-layouts-columnlayout.html#details
        Layout.preferredWidth: parent.width
        spacing: MZTheme.theme.windowMargin
        delegate: RowLayout {
            property string appIdForFunctionalTests: appID
            id: appRow

            objectName: `app-${index}`
            spacing: MZTheme.theme.windowMargin
            opacity: enabled ? 1.0 : 0.5
            Layout.preferredHeight: MZTheme.theme.navBarTopMargin

            function handleClick() {
                VPNAppPermissions.flip(appID)
            }

            MZCheckBox {
                id: checkBox
                objectName: "checkbox"
                onClicked: () => appRow.handleClick()
                checked: !appIsEnabled
                Layout.alignment: Qt.AlignVCenter
                Accessible.name: appID
            }

            Rectangle {
                Layout.preferredWidth: MZTheme.theme.windowMargin * 2
                Layout.preferredHeight: MZTheme.theme.windowMargin * 2
                Layout.maximumHeight: MZTheme.theme.windowMargin * 2
                Layout.maximumWidth: MZTheme.theme.windowMargin * 2
                Layout.alignment: Qt.AlignVCenter
                color: MZTheme.theme.transparent

                Image {
                    height: MZTheme.theme.windowMargin * 2
                    width: MZTheme.theme.windowMargin * 2
                    sourceSize.width: MZTheme.theme.windowMargin * 2
                    sourceSize.height: MZTheme.theme.windowMargin * 2
                    anchors.centerIn: parent
                    fillMode:  Image.PreserveAspectFit
                    Component.onCompleted: {
                        if (appID !== "") {
                            source = "image://app/"+appID
                        }
                    }
                    
                }
            }

            MZInterLabel {
                id: label
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.fillWidth: true
                text: appName
                color: MZTheme.theme.fontColorDark
                horizontalAlignment: Text.AlignLeft

                MZMouseArea {
                    anchors.fill: undefined
                    width: parent.implicitWidth
                    height: parent.implicitHeight
                    propagateClickToParent: false
                    onClicked: () => appRow.handleClick()
                }
            }
        }
        header: appListHeader
        footer: appListFooter
    }

    Component {
        id: appListFooter

        ColumnLayout {
            id: appListFooterColumn

            spacing: MZTheme.theme.vSpacingSmall
            width: applist.width - (3 * MZTheme.theme.windowMargin)

            MZVerticalSpacer {
                height: MZTheme.theme.dividerHeight
            }

            MZLinkButton {
                objectName: "addApplication"
                id: addApp
                labelText: addApplication
                textAlignment: Text.AlignLeft
                fontSize: MZTheme.theme.fontSize
                fontName: MZTheme.theme.fontInterSemiBoldFamily
                onClicked: {
                    Glean.interaction.addApplicationSelected.record({screen:telemetryScreenId});
                    VPNAppPermissions.openFilePicker()
                }

                // Hack to horizontally align the "+" sign with the
                // column of checkboxes
                Layout.leftMargin: -1

                visible: Qt.platform.os === "windows"
                iconComponent: Component {
                    MZIcon {
                        source: "qrc:/nebula/resources/plus.svg"
                        sourceSize.height: MZTheme.theme.iconSmallSize
                        sourceSize.width: MZTheme.theme.iconSmallSize
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}

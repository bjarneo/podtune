import QtQuick

Item {
    id: section
    default property alias content: column.data
    property real bottomGap: 14
    property bool divided: true
    width: parent ? parent.width : 0
    implicitHeight: 20 + column.implicitHeight + bottomGap + (divided ? 1 : 0)

    Column { id: column; y: 20; width: parent.width }
    Rectangle { visible: section.divided; anchors.bottom: parent.bottom; width: parent.width; height: 1; color: theme.line }
}

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    property int messageIndex
    property var messageData
    property var messageInputField

    property real messagePadding: 7
    property real contentSpacing: 3

    property bool enableMouseSelection: false
    property bool renderMarkdown: true
    property bool editing: false

    readonly property bool streaming: root.messageData?.role === "assistant" && !(root.messageData?.done ?? true)
    readonly property var assistantModel: messageData?.model ? Ai.models[messageData.model] : null
    property var streamingSettledBlocks: []
    property var streamingTailBlock: null

    // Important:
    // Do not split markdown while streaming.
    // Re-splitting/rebuilding delegates during generation causes height jitter.
    property list<var> messageBlocks: root.streaming ? [] : StringUtils.splitMarkdownBlocks(root.messageData?.content ?? "")
        .filter(block => block.type !== "think")

    anchors.left: parent?.left
    anchors.right: parent?.right

    implicitHeight: columnLayout.implicitHeight + root.messagePadding * 2

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    function blockMatches(left, right) {
        if (!left || !right) {
            return left === right;
        }

        return left.type === right.type
            && left.content === right.content
            && (left.lang ?? "") === (right.lang ?? "")
            && (left.completed ?? false) === (right.completed ?? false);
    }

    function blocksMatch(leftBlocks, rightBlocks) {
        if ((leftBlocks?.length ?? 0) !== (rightBlocks?.length ?? 0)) {
            return false;
        }

        for (let i = 0; i < leftBlocks.length; i++) {
            if (!root.blockMatches(leftBlocks[i], rightBlocks[i])) {
                return false;
            }
        }

        return true;
    }

    function updateStreamingRenderState() {
        if (!root.streaming) {
            if (root.streamingSettledBlocks.length > 0) {
                root.streamingSettledBlocks = [];
            }

            if (root.streamingTailBlock) {
                root.streamingTailBlock = null;
            }

            return;
        }

        const visibleBlocks = StringUtils.splitMarkdownBlocks(root.messageData?.content ?? "")
            .filter(block => block.type !== "think");

        const nextSettledBlocks = visibleBlocks.length > 1
            ? visibleBlocks.slice(0, visibleBlocks.length - 1)
            : [];
        const nextTailBlock = visibleBlocks.length > 0
            ? visibleBlocks[visibleBlocks.length - 1]
            : null;

        // Only replace the settled array when a block boundary changes.
        if (!root.blocksMatch(root.streamingSettledBlocks, nextSettledBlocks)) {
            root.streamingSettledBlocks = nextSettledBlocks;
        }

        if (!root.blockMatches(root.streamingTailBlock, nextTailBlock)) {
            root.streamingTailBlock = nextTailBlock;
        }

        root.requestListRelayout();
    }

    function requestListRelayout() {
        if (!relayoutTimer.running) {
            relayoutTimer.start();
        }
    }

    Timer {
        id: relayoutTimer
        interval: 0
        repeat: false

        onTriggered: {
            ListView.view?.forceLayout();
        }
    }

    onMessageDataChanged: updateStreamingRenderState()
    onStreamingChanged: updateStreamingRenderState()
    onImplicitHeightChanged: requestListRelayout()

    Component.onCompleted: {
        updateStreamingRenderState();
    }

    Connections {
        target: root.messageData
        ignoreUnknownSignals: true

        function onContentChanged() {
            root.updateStreamingRenderState();
        }

        function onDoneChanged() {
            root.updateStreamingRenderState();
        }
    }

    function saveMessage() {
        if (!root.editing) return;

        const segments = messageContentColumnLayout.children
            .map(child => child.segment)
            .filter(segment => (segment));

        const newContent = segments.map(segment => {
            if (segment.type === "code") {
                const lang = segment.lang ? segment.lang : "";
                const code = segment.content.replace(/\n+$/, "");
                return "```" + lang + "\n" + code + "\n```";
            } else {
                return segment.content;
            }
        }).join("");

        root.editing = false;
        root.messageData.content = newContent;
    }

    Keys.onPressed: event => {
        if (
            event.key === Qt.Key_Control ||
            event.key === Qt.Key_Shift ||
            event.key === Qt.Key_Alt ||
            event.key === Qt.Key_Meta
        ) {
            event.accepted = true;
        }

        if ((event.key === Qt.Key_S) && event.modifiers == Qt.ControlModifier) {
            root.saveMessage();
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: columnLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: messagePadding

        spacing: root.contentSpacing

        Rectangle {
            Layout.fillWidth: true
            implicitWidth: headerRowLayout.implicitWidth + 4 * 2
            implicitHeight: headerRowLayout.implicitHeight + 4 * 2
            color: Appearance.colors.colSecondaryContainer
            radius: Appearance.rounding.small

            RowLayout {
                id: headerRowLayout

                anchors {
                    fill: parent
                    margins: 4
                }

                spacing: 18

                Item {
                    id: nameWrapper
                    implicitHeight: Math.max(nameRowLayout.implicitHeight + 5 * 2, 30)
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    RowLayout {
                        id: nameRowLayout

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        spacing: 12

                        Item {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillHeight: true

                            implicitWidth: messageData?.role == "assistant" ? modelIcon.width : roleIcon.implicitWidth
                            implicitHeight: messageData?.role == "assistant" ? modelIcon.height : roleIcon.implicitHeight

                            CustomIcon {
                                id: modelIcon

                                anchors.centerIn: parent

                                visible: messageData?.role == "assistant" && !!root.assistantModel?.icon
                                width: Appearance.font.pixelSize.large
                                height: Appearance.font.pixelSize.large

                                source: messageData?.role == "assistant" ? (root.assistantModel?.icon ?? "") :
                                    messageData?.role == "user" ? "linux-symbolic" : "desktop-symbolic"

                                colorize: true
                                color: Appearance.m3colors.m3onSecondaryContainer
                            }

                            MaterialSymbol {
                                id: roleIcon

                                anchors.centerIn: parent
                                visible: !modelIcon.visible

                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.m3colors.m3onSecondaryContainer

                                text: messageData?.role == "user" ? "person" :
                                    messageData?.role == "interface" ? "settings" :
                                    messageData?.role == "assistant" ? "neurology" :
                                    "computer"
                            }
                        }

                        StyledText {
                            id: providerName

                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true

                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.m3colors.m3onSecondaryContainer

                            text: messageData?.role == "assistant" ? (root.assistantModel?.name ?? Translation.tr("Assistant")) :
                                (messageData?.role == "user" && SystemInfo.username) ? SystemInfo.username :
                                Translation.tr("Interface")
                        }
                    }
                }

                Button {
                    id: modelVisibilityIndicator

                    visible: messageData?.role == "interface"
                    implicitWidth: 16
                    implicitHeight: 30
                    Layout.alignment: Qt.AlignVCenter

                    background: Item {}

                    MaterialSymbol {
                        id: notVisibleToModelText

                        anchors.centerIn: parent
                        iconSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        text: "visibility_off"
                    }

                    StyledToolTip {
                        text: Translation.tr("Not visible to model")
                    }
                }

                ButtonGroup {
                    spacing: 5

                    AiMessageControlButton {
                        id: regenButton

                        buttonIcon: "refresh"
                        visible: messageData?.role === "assistant"

                        onClicked: {
                            Ai.regenerate(root.messageIndex);
                        }

                        StyledToolTip {
                            text: Translation.tr("Regenerate")
                        }
                    }

                    AiMessageControlButton {
                        id: copyButton

                        buttonIcon: activated ? "inventory" : "content_copy"

                        onClicked: {
                            Quickshell.clipboardText = root.messageData?.content;
                            copyButton.activated = true;
                            copyIconTimer.restart();
                        }

                        Timer {
                            id: copyIconTimer
                            interval: 1500
                            repeat: false

                            onTriggered: {
                                copyButton.activated = false;
                            }
                        }

                        StyledToolTip {
                            text: Translation.tr("Copy")
                        }
                    }

                    AiMessageControlButton {
                        id: editButton

                        activated: root.editing
                        enabled: root.messageData?.done ?? false
                        buttonIcon: "edit"

                        onClicked: {
                            root.editing = !root.editing;

                            if (!root.editing) {
                                root.saveMessage();
                            }
                        }

                        StyledToolTip {
                            text: root.editing ? Translation.tr("Save") : Translation.tr("Edit")
                        }
                    }

                    AiMessageControlButton {
                        id: toggleMarkdownButton

                        activated: !root.renderMarkdown
                        buttonIcon: "code"

                        onClicked: {
                            root.renderMarkdown = !root.renderMarkdown;
                        }

                        StyledToolTip {
                            text: Translation.tr("View Markdown source")
                        }
                    }

                    AiMessageControlButton {
                        id: deleteButton

                        buttonIcon: "close"

                        onClicked: {
                            Ai.removeMessage(root.messageIndex);
                        }

                        StyledToolTip {
                            text: Translation.tr("Delete")
                        }
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.preferredHeight: active ? implicitHeight : 0

            active: (root.messageData?.localFilePath?.length ?? 0) > 0
            visible: active

            sourceComponent: AttachedFileIndicator {
                filePath: root.messageData?.localFilePath
                canRemove: false
            }
        }

        ColumnLayout {
            id: messageContentColumnLayout

            Layout.fillWidth: true
            spacing: 0

            Item {
                Layout.fillWidth: true

                implicitHeight: loadingIndicatorLoader.shown ? loadingIndicatorLoader.implicitHeight : 0
                implicitWidth: loadingIndicatorLoader.implicitWidth
                visible: implicitHeight > 0

                // No Behavior here.
                // Animating this height while the first streamed text appears causes list jitter.

                FadeLoader {
                    id: loadingIndicatorLoader

                    anchors.centerIn: parent

                    shown: root.streaming && !root.streamingTailBlock && root.streamingSettledBlocks.length < 1

                    sourceComponent: MaterialLoadingIndicator {
                        loading: true
                    }
                }
            }

            Repeater {
                model: ScriptModel {
                    values: root.streaming ? root.streamingSettledBlocks : root.messageBlocks
                }

                delegate: DelegateChooser {
                    id: messageDelegate
                    role: "type"

                    DelegateChoice {
                        roleValue: "code"

                        MessageCodeBlock {
                            editing: root.editing
                            renderMarkdown: root.renderMarkdown
                            enableMouseSelection: root.enableMouseSelection

                            segmentContent: modelData.content
                            segmentLang: modelData.lang
                            messageData: root.messageData
                        }
                    }

                    DelegateChoice {
                        roleValue: "text"

                        MessageTextBlock {
                            editing: root.editing
                            renderMarkdown: root.renderMarkdown
                            enableMouseSelection: root.enableMouseSelection

                            segmentContent: modelData.content
                            messageData: root.messageData

                            done: root.messageData?.done ?? false
                            forceDisableChunkSplitting: root.streaming || (root.messageData?.content?.includes("```") ?? true)
                        }
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: active ? implicitHeight : 0
                active: root.streaming && !root.editing && !!root.streamingTailBlock
                visible: active

                sourceComponent: root.streamingTailBlock?.type === "code" ? streamingCodeBlockComponent
                    : root.streamingTailBlock?.type === "text" ? streamingTextBlockComponent
                    : null
            }
        }

        Flow {
            visible: root.messageData?.annotationSources?.length > 0
            spacing: 5
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            Layout.preferredHeight: visible ? implicitHeight : 0

            Repeater {
                model: ScriptModel {
                    values: root.messageData?.annotationSources || []
                }

                delegate: AnnotationSourceButton {
                    required property var modelData

                    displayText: modelData.text
                    url: modelData.url
                }
            }
        }

        Flow {
            visible: root.messageData?.searchQueries?.length > 0
            spacing: 5
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            Layout.preferredHeight: visible ? implicitHeight : 0

            Repeater {
                model: ScriptModel {
                    values: root.messageData?.searchQueries || []
                }

                delegate: SearchQueryButton {
                    required property var modelData

                    query: modelData
                }
            }
        }
    }

    Component {
        id: streamingTextBlockComponent

        MessageTextBlock {
            editing: false
            renderMarkdown: true
            enableMouseSelection: root.enableMouseSelection

            segmentContent: root.streamingTailBlock?.content ?? ""
            messageData: root.messageData

            done: false
            forceDisableChunkSplitting: true
        }
    }

    Component {
        id: streamingCodeBlockComponent

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            readonly property string segmentLang: root.streamingTailBlock?.lang ?? ""

            Rectangle {
                Layout.fillWidth: true
                topLeftRadius: Appearance.rounding.small
                topRightRadius: Appearance.rounding.small
                bottomLeftRadius: Appearance.rounding.unsharpen
                bottomRightRadius: Appearance.rounding.unsharpen
                color: Appearance.colors.colSurfaceContainerHighest
                implicitHeight: codeLanguageLabel.implicitHeight + 14

                StyledText {
                    id: codeLanguageLabel

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 13

                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer2
                        text: parent.parent.segmentLang || "code"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                color: Appearance.colors.colLayer2
                topLeftRadius: Appearance.rounding.unsharpen
                topRightRadius: Appearance.rounding.unsharpen
                bottomLeftRadius: Appearance.rounding.small
                bottomRightRadius: Appearance.rounding.small
                implicitHeight: Math.ceil(streamingCodeText.contentHeight) + 12
                clip: true

                Flickable {
                    id: streamingCodeFlickable

                    anchors.fill: parent
                    anchors.margins: 6

                    contentWidth: Math.max(width, streamingCodeText.contentWidth)
                    contentHeight: height
                    boundsBehavior: Flickable.StopAtBounds
                    boundsMovement: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick
                    clip: true

                    TextEdit {
                        id: streamingCodeText

                        width: Math.max(streamingCodeFlickable.width, contentWidth)
                        readOnly: true
                        selectByMouse: root.enableMouseSelection
                        renderType: Text.NativeRendering
                        wrapMode: TextEdit.NoWrap
                        font.family: Appearance.font.family.monospace
                        font.hintingPreference: Font.PreferNoHinting
                        font.pixelSize: Appearance.font.pixelSize.small
                        selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                        selectionColor: Appearance.colors.colSecondaryContainer
                        color: Appearance.colors.colOnLayer1
                        text: String(root.streamingTailBlock?.content ?? "").replace(/\n+$/, "")
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton

                        onWheel: wheel => {
                            const horizontalDelta = wheel.pixelDelta.x !== 0 ? wheel.pixelDelta.x : wheel.angleDelta.x;
                            const verticalDelta = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y : wheel.angleDelta.y;

                            if (Math.abs(horizontalDelta) > Math.abs(verticalDelta) && horizontalDelta !== 0) {
                                const maxContentX = Math.max(0, streamingCodeFlickable.contentWidth - streamingCodeFlickable.width);
                                streamingCodeFlickable.contentX = Math.max(0, Math.min(maxContentX, streamingCodeFlickable.contentX - horizontalDelta));
                                wheel.accepted = true;
                                return;
                            }

                            wheel.accepted = false;
                        }
                    }
                }
            }
        }
    }
}

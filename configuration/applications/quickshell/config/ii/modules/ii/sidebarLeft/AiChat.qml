import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarLeft.aiChat
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real padding: 4
    property var inputField: messageInputField
    property string commandPrefix: "/"

    property var suggestionQuery: ""
    property var suggestionList: []

    onFocusChanged: focus => {
        if (focus) {
            root.inputField.forceActiveFocus();
        }
    }

    Keys.onPressed: event => {
        messageInputField.forceActiveFocus();

        if (event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageUp) {
                messageListView.stickToBottom = false;
                messageListView.contentY = messageListView.clampY(
                    messageListView.contentY - messageListView.height / 2
                );
                event.accepted = true;
            } else if (event.key === Qt.Key_PageDown) {
                messageListView.contentY = messageListView.clampY(
                    messageListView.contentY + messageListView.height / 2
                );
                messageListView.stickToBottom = messageListView.nearBottom();
                event.accepted = true;
            }
        }

        if ((event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_O) {
            Ai.clearMessages();
        }
    }

    property var allCommands: [
        {
            name: "model",
            description: Translation.tr("Choose model"),
            execute: args => {
                Ai.setModel(args[0]);
            }
        },
        {
            name: "tool",
            description: Translation.tr("Set the tool mode to search or none. Search is currently not backed by a live web search provider."),
            execute: args => {
                if (args.length == 0 || args[0] == "get") {
                    Ai.addMessage(Translation.tr("Usage: %1tool TOOL_NAME").arg(root.commandPrefix), Ai.interfaceRole);
                } else {
                    const tool = args[0];
                    const switched = Ai.setTool(tool);
                    if (switched) {
                        Ai.addMessage(Translation.tr("Tool set to: %1").arg(tool), Ai.interfaceRole);
                    }
                }
            }
        },
        {
            name: "clear",
            description: Translation.tr("Clear chat history"),
            execute: () => {
                Ai.clearMessages();
            }
        },
    ]

    function handleInput(inputText) {
        if (inputText.startsWith(root.commandPrefix)) {
            const command = inputText.split(" ")[0].substring(1);
            const args = inputText.split(" ").slice(1);
            const commandObj = root.allCommands.find(cmd => cmd.name === `${command}`);

            if (commandObj) {
                commandObj.execute(args);
            } else {
                Ai.addMessage(Translation.tr("Unknown command: ") + command, Ai.interfaceRole);
            }
        } else {
            Ai.sendUserMessage(inputText);
        }

        messageListView.stickToBottom = true;
        messageListView.snapToBottom();
    }

    Process {
        id: decodeImageAndAttachProc
        property string imageDecodePath: Directories.cliphistDecode
        property string imageDecodeFileName: "image"
        property string imageDecodeFilePath: `${imageDecodePath}/${imageDecodeFileName}`

        function handleEntry(entry: string) {
            imageDecodeFileName = parseInt(entry.match(/^(\d+)\t/)[1]);
            decodeImageAndAttachProc.exec(["bash", "-c", `[ -f ${imageDecodeFilePath} ] || echo '${StringUtils.shellSingleQuoteEscape(entry)}' | ${Cliphist.cliphistBinary} decode > '${imageDecodeFilePath}'`]);
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                Ai.attachFile(imageDecodeFilePath);
            } else {
                console.error("[AiChat] Failed to decode image in clipboard content");
            }
        }
    }

    component StatusItem: MouseArea {
        id: statusItem
        property string icon
        property string statusText
        property string description
        hoverEnabled: true
        implicitHeight: statusItemRowLayout.implicitHeight
        implicitWidth: statusItemRowLayout.implicitWidth

        RowLayout {
            id: statusItemRowLayout
            spacing: 0

            MaterialSymbol {
                text: statusItem.icon
                iconSize: Appearance.font.pixelSize.huge
                color: "#8f8f8f"
            }

            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                text: statusItem.statusText
                color: "#8f8f8f"
                animateChange: true
            }
        }

        StyledToolTip {
            text: statusItem.description
            extraVisibleCondition: false
            alternativeVisibleCondition: statusItem.containsMouse
        }
    }

    component StatusSeparator: Rectangle {
        implicitWidth: 4
        implicitHeight: 4
        radius: implicitWidth / 2
        color: "#8f8f8f"
    }

    ColumnLayout {
        id: columnLayout

        anchors {
            fill: parent
            margins: root.padding
        }

        spacing: root.padding

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            layer.enabled: true

            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: messageListView.width
                    height: messageListView.height
                    radius: Appearance.rounding.small
                }
            }

            StyledRectangularShadow {
                z: 1
                target: statusBg
                opacity: messageListView.atYBeginning ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            Item {
                id: statusBg
                z: 2

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 4
                }

                implicitWidth: statusRowLayout.implicitWidth + 10 * 2
                implicitHeight: statusRowLayout.visible ? Math.max(statusRowLayout.implicitHeight, 38) : 0
                visible: statusRowLayout.visible

                RowLayout {
                    id: statusRowLayout
                    anchors.centerIn: parent
                    spacing: 10
                    visible: Ai.tokenCount.total > 0

                    StatusItem {
                        icon: "token"
                        statusText: Ai.tokenCount.total
                        description: Translation.tr("Total token count\nInput: %1\nOutput: %2").arg(Ai.tokenCount.input).arg(Ai.tokenCount.output)
                    }
                }
            }

            ScrollEdgeFade {
                z: 1
                target: messageListView
                vertical: true
            }

            StyledListView {
                id: messageListView
                z: 0
                anchors.fill: parent
                spacing: 10
                popin: false
                animateScroll: false

                customWheelScrolling: false
                readonly property real wheelScrollMultiplier: 6.6 * 0.5
                touchpadScrollFactor: Config.options.interactions.scrolling.touchpadScrollFactor * wheelScrollMultiplier
                mouseScrollFactor: Config.options.interactions.scrolling.mouseScrollFactor * wheelScrollMultiplier

                boundsBehavior: Flickable.StopAtBounds
                boundsMovement: Flickable.StopAtBounds

                topMargin: statusBg.implicitHeight + statusBg.anchors.topMargin * 2
                // Large temporary buffer prevents Qt from clamping contentY upward
                // when streamed text temporarily reflows smaller.
                bottomMargin: streamingReplyActive && stickToBottom ? Math.max(8192, height * 8) : 0

                property bool stickToBottom: true
                property bool autoScrolling: false
                property bool userScrolling: false
                property real pinnedStreamingY: 0

                readonly property bool streamingReplyActive: {
                    const lastId = Ai.messageIDs[Ai.messageIDs.length - 1];
                    const lastMessage = lastId ? Ai.messageByID[lastId] : null;
                    return lastMessage?.role === "assistant" && !(lastMessage?.done ?? true);
                }

                function minY() {
                    return originY - topMargin;
                }

                function visualBottomY() {
                    if (count > 0) {
                        const lastItem = itemAtIndex(count - 1);
                        if (lastItem) {
                            return Math.max(minY(), lastItem.y + lastItem.height - height);
                        }
                    }

                    return Math.max(minY(), originY + contentHeight - height);
                }

                function hardMaxY() {
                    return Math.max(minY(), originY + contentHeight + bottomMargin - height);
                }

                function clampY(y) {
                    return Math.max(minY(), Math.min(visualBottomY(), y));
                }

                function clampHardY(y) {
                    return Math.max(minY(), Math.min(hardMaxY(), y));
                }

                function nearBottom() {
                    return visualBottomY() - contentY < 96;
                }

                function setScrollY(y) {
                    autoScrolling = true;
                    cancelFlick();
                    contentY = clampHardY(y);
                    clearAutoScrollingTimer.restart();
                }

                function snapToBottom() {
                    pinnedStreamingY = 0;
                    setScrollY(visualBottomY());
                }

                function startStreamingPin() {
                    pinnedStreamingY = Math.max(contentY, visualBottomY());
                    setScrollY(pinnedStreamingY);
                }

                function followStreamingBottom() {
                    const target = visualBottomY();

                    // While streaming, contentY can move down, but never up.
                    pinnedStreamingY = Math.max(pinnedStreamingY, contentY, target);
                    setScrollY(pinnedStreamingY);
                }

                function requestStreamingFollow() {
                    if (!streamingFollowTimer.running) {
                        streamingFollowTimer.start();
                    }
                }

                function updateStickToBottomFromPosition() {
                    if (!autoScrolling) {
                        stickToBottom = nearBottom();

                        if (!stickToBottom) {
                            pinnedStreamingY = 0;
                        }
                    }
                }

                Timer {
                    id: clearAutoScrollingTimer
                    interval: 120
                    repeat: false

                    onTriggered: {
                        messageListView.autoScrolling = false;
                    }
                }

                Timer {
                    id: streamingFollowTimer
                    interval: 16
                    repeat: false

                    onTriggered: {
                        if (messageListView.stickToBottom && !messageListView.userScrolling && messageListView.streamingReplyActive) {
                            messageListView.followStreamingBottom();
                        }
                    }
                }

                Timer {
                    id: wheelScrollEndTimer
                    interval: 120
                    repeat: false

                    onTriggered: {
                        messageListView.userScrolling = false;
                        messageListView.updateStickToBottomFromPosition();

                        if (messageListView.stickToBottom && Math.abs(messageListView.visualBottomY() - messageListView.contentY) < 1) {
                            if (messageListView.streamingReplyActive) {
                                messageListView.startStreamingPin();
                                messageListView.requestStreamingFollow();
                            } else {
                                messageListView.snapToBottom();
                            }
                        }
                    }
                }

                WheelHandler {
                    enabled: true
                    target: messageListView
                    orientation: Qt.Vertical
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                    onWheel: event => {
                        const delta = event.angleDelta.y / messageListView.mouseScrollDeltaThreshold;
                        const isMouse = Math.abs(event.angleDelta.y) >= messageListView.mouseScrollDeltaThreshold;
                        const scrollFactor = isMouse ? messageListView.mouseScrollFactor : messageListView.touchpadScrollFactor;
                        const targetY = messageListView.clampY(messageListView.contentY - delta * scrollFactor);
                        const scrollingUp = targetY + 1 < messageListView.contentY;

                        messageListView.userScrolling = true;
                        messageListView.autoScrolling = false;
                        messageListView.pinnedStreamingY = 0;
                        messageListView.cancelFlick();
                        messageListView.contentY = targetY;
                        messageListView.scrollTargetY = targetY;

                        if (scrollingUp) {
                            messageListView.stickToBottom = false;
                        } else {
                            messageListView.stickToBottom = Math.abs(messageListView.visualBottomY() - targetY) < 1;
                        }

                        wheelScrollEndTimer.restart();
                        event.accepted = true;
                    }
                }

                onMovementStarted: {
                    userScrolling = true;
                    updateStickToBottomFromPosition();
                }

                onMovementEnded: {
                    updateStickToBottomFromPosition();
                    userScrolling = false;
                }

                onDraggingChanged: {
                    if (dragging) {
                        userScrolling = true;
                        updateStickToBottomFromPosition();
                    } else {
                        updateStickToBottomFromPosition();
                        userScrolling = false;
                    }
                }

                onFlickingChanged: {
                    if (flicking) {
                        userScrolling = true;
                        updateStickToBottomFromPosition();
                    } else {
                        updateStickToBottomFromPosition();
                        userScrolling = false;
                    }
                }

                onContentYChanged: {
                    if (streamingReplyActive && stickToBottom && !userScrolling) {
                        if (!autoScrolling && pinnedStreamingY > 0 && contentY + 1 < pinnedStreamingY) {
                            requestStreamingFollow();
                        }
                        return;
                    }

                    if (!autoScrolling && (moving || dragging || flicking)) {
                        updateStickToBottomFromPosition();
                    }
                }

                onContentHeightChanged: {
                    if (stickToBottom && !userScrolling) {
                        if (streamingReplyActive) {
                            requestStreamingFollow();
                        } else {
                            snapToBottom();
                        }
                    }
                }

                onStreamingReplyActiveChanged: {
                    if (streamingReplyActive) {
                        Qt.callLater(() => {
                            startStreamingPin();
                            requestStreamingFollow();
                        });
                    } else {
                        Qt.callLater(() => {
                            pinnedStreamingY = 0;

                            if (stickToBottom && !userScrolling) {
                                snapToBottom();
                            }
                        });
                    }
                }

                onHeightChanged: {
                    if (stickToBottom && !userScrolling) {
                        if (streamingReplyActive) {
                            requestStreamingFollow();
                        } else {
                            snapToBottom();
                        }
                    }
                }

                onTopMarginChanged: {
                    if (stickToBottom && !userScrolling) {
                        if (streamingReplyActive) {
                            requestStreamingFollow();
                        } else {
                            snapToBottom();
                        }
                    }
                }

                onBottomMarginChanged: {
                    if (stickToBottom && !userScrolling && !streamingReplyActive) {
                        snapToBottom();
                    }
                }

                onCountChanged: {
                    if (stickToBottom && !userScrolling) {
                        Qt.callLater(() => {
                            if (streamingReplyActive) {
                                startStreamingPin();
                                requestStreamingFollow();
                            } else {
                                snapToBottom();
                            }
                        });
                    }
                }

                add: null

                model: ScriptModel {
                    values: Ai.messageIDs.filter(id => {
                        const message = Ai.messageByID[id];
                        return message?.visibleToUser ?? true;
                    })
                }

                delegate: AiMessage {
                    required property var modelData
                    required property int index
                    messageIndex: index
                    messageData: Ai.messageByID[modelData]
                    messageInputField: root.inputField
                }
            }

            PagePlaceholder {
                z: 2
                shown: Ai.messageIDs.length === 0
                icon: "neurology"
                title: Translation.tr("Local language models")
                description: Translation.tr("Install Ollama models to get started\nUse /model to switch models\nCtrl+O to expand sidebar\nCtrl+P to pin sidebar")
                shape: MaterialShape.Shape.PixelCircle
            }

        }

        DescriptionBox {
            text: root.suggestionList[suggestions.selectedIndex]?.description ?? ""
            showArrows: root.suggestionList.length > 1
        }

        FlowButtonGroup {
            id: suggestions
            visible: root.suggestionList.length > 0 && messageInputField.text.length > 0
            property int selectedIndex: 0
            Layout.fillWidth: true
            spacing: 5

            Repeater {
                id: suggestionRepeater

                model: {
                    suggestions.selectedIndex = 0;
                    return root.suggestionList.slice(0, 10);
                }

                delegate: ApiCommandButton {
                    id: commandButton
                    colBackground: suggestions.selectedIndex === index ? "#262626" : "#181818"
                    bounce: false

                    contentItem: StyledText {
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: "#f5f5f5"
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.displayName ?? modelData.name
                    }

                    onHoveredChanged: {
                        if (commandButton.hovered) {
                            suggestions.selectedIndex = index;
                        }
                    }

                    onClicked: {
                        suggestions.acceptSuggestion(modelData.name);
                    }
                }
            }

            function acceptSuggestion(word) {
                const words = messageInputField.text.trim().split(/\s+/);

                if (words.length > 0) {
                    words[words.length - 1] = word;
                } else {
                    words.push(word);
                }

                const updatedText = words.join(" ") + " ";
                messageInputField.text = updatedText;
                messageInputField.cursorPosition = messageInputField.text.length;
                messageInputField.forceActiveFocus();
            }

            function acceptSelectedWord() {
                if (suggestions.selectedIndex >= 0 && suggestions.selectedIndex < suggestionRepeater.count) {
                    const word = root.suggestionList[suggestions.selectedIndex].name;
                    suggestions.acceptSuggestion(word);
                }
            }
        }

        Rectangle {
            id: inputWrapper
            property real spacing: 5
            Layout.fillWidth: true
            radius: Appearance.rounding.normal - root.padding
            color: "#181818"
            border.width: 1
            border.color: "#262626"
            implicitHeight: Math.max(inputFieldRowLayout.implicitHeight + inputFieldRowLayout.anchors.topMargin + commandButtonsRow.implicitHeight + commandButtonsRow.anchors.bottomMargin + spacing, 45) + (attachedFileIndicator.implicitHeight + spacing + attachedFileIndicator.anchors.topMargin)
            clip: true

            Behavior on implicitHeight {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }

            AttachedFileIndicator {
                id: attachedFileIndicator

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: visible ? 5 : 0
                }

                filePath: Ai.pendingFilePath
                onRemove: Ai.attachFile("")
            }

            RowLayout {
                id: inputFieldRowLayout

                anchors {
                    bottom: commandButtonsRow.top
                    left: parent.left
                    right: parent.right
                    bottomMargin: 5
                }

                spacing: 0

                ScrollView {
                    id: inputScrollView
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(root.height * 3 / 5, messageInputField.height)
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    StyledTextArea {
                        id: messageInputField
                        anchors.fill: parent
                        wrapMode: TextArea.Wrap
                        padding: 10
                        color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                        placeholderText: Translation.tr('Message the model... "%1" for commands').arg(root.commandPrefix)
                        background: null

                        onTextChanged: {
                            if (messageInputField.text.length === 0) {
                                root.suggestionQuery = "";
                                root.suggestionList = [];
                                return;
                            } else if (messageInputField.text.startsWith(`${root.commandPrefix}model`)) {
                                root.suggestionQuery = messageInputField.text.split(" ")[1] ?? "";

                                const modelResults = Fuzzy.go(root.suggestionQuery, Ai.modelList.map(model => {
                                    return {
                                        name: Fuzzy.prepare(model),
                                        obj: model
                                    };
                                }), {
                                    all: true,
                                    key: "name"
                                });

                                root.suggestionList = modelResults.map(model => {
                                    return {
                                        name: `${messageInputField.text.trim().split(" ").length == 1 ? (root.commandPrefix + "model ") : ""}${model.target}`,
                                        displayName: `${Ai.models[model.target].name}`,
                                        description: `${Ai.models[model.target].description}`
                                    };
                                });
                            } else if (messageInputField.text.startsWith(`${root.commandPrefix}tool`)) {
                                root.suggestionQuery = messageInputField.text.split(" ")[1] ?? "";

                                const toolResults = Fuzzy.go(root.suggestionQuery, Ai.availableTools.map(tool => {
                                    return {
                                        name: Fuzzy.prepare(tool),
                                        obj: tool
                                    };
                                }), {
                                    all: true,
                                    key: "name"
                                });

                                root.suggestionList = toolResults.map(tool => {
                                    const toolName = tool.target;

                                    return {
                                        name: `${messageInputField.text.trim().split(" ").length == 1 ? (root.commandPrefix + "tool ") : ""}${tool.target}`,
                                        displayName: toolName,
                                        description: Ai.toolDescriptions[toolName]
                                    };
                                });
                            } else if (messageInputField.text.startsWith(root.commandPrefix)) {
                                root.suggestionQuery = messageInputField.text;
                                root.suggestionList = root.allCommands.filter(cmd => cmd.name.startsWith(messageInputField.text.substring(1))).map(cmd => {
                                    return {
                                        name: `${root.commandPrefix}${cmd.name}`,
                                        description: `${cmd.description}`
                                    };
                                });
                            }
                        }

                        function accept() {
                            root.handleInput(text);
                            text = "";
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Tab) {
                                suggestions.acceptSelectedWord();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up && suggestions.visible) {
                                suggestions.selectedIndex = Math.max(0, suggestions.selectedIndex - 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down && suggestions.visible) {
                                suggestions.selectedIndex = Math.min(root.suggestionList.length - 1, suggestions.selectedIndex + 1);
                                event.accepted = true;
                            } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    messageInputField.insert(messageInputField.cursorPosition, "\n");
                                    event.accepted = true;
                                } else {
                                    const inputText = messageInputField.text;
                                    messageInputField.clear();
                                    root.handleInput(inputText);
                                    event.accepted = true;
                                }
                            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    messageInputField.text += Quickshell.clipboardText;
                                    event.accepted = true;
                                    return;
                                }

                                const currentClipboardEntry = Cliphist.entries[0];
                                const cleanCliphistEntry = StringUtils.cleanCliphistEntry(currentClipboardEntry);

                                if (/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(currentClipboardEntry)) {
                                    decodeImageAndAttachProc.handleEntry(currentClipboardEntry);
                                    event.accepted = true;
                                    return;
                                } else if (cleanCliphistEntry.startsWith("file://")) {
                                    const fileName = decodeURIComponent(cleanCliphistEntry);
                                    Ai.attachFile(fileName);
                                    event.accepted = true;
                                    return;
                                }

                                event.accepted = false;
                            } else if (event.key === Qt.Key_Escape) {
                                if (Ai.pendingFilePath.length > 0) {
                                    Ai.attachFile("");
                                    event.accepted = true;
                                } else {
                                    event.accepted = false;
                                }
                            }
                        }
                    }
                }

                RippleButton {
                    id: sendButton
                    Layout.alignment: Qt.AlignBottom
                    Layout.rightMargin: 5
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    enabled: messageInputField.text.length > 0
                    toggled: enabled

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: sendButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onClicked: {
                            const inputText = messageInputField.text;
                            root.handleInput(inputText);
                            messageInputField.clear();
                        }
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: 22
                        color: sendButton.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2Disabled
                        text: "arrow_upward"
                    }
                }
            }

            RowLayout {
                id: commandButtonsRow

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: 5
                    leftMargin: 10
                    rightMargin: 5
                }

                spacing: 4

                property var commandsShown: [
                    {
                        name: "",
                        sendDirectly: false,
                        dontAddSpace: true
                    },
                    {
                        name: "clear",
                        sendDirectly: true
                    },
                ]

                ApiInputBoxIndicator {
                    icon: "api"
                    text: Ai.getModel()?.name ?? Translation.tr("No model")
                    tooltipText: Translation.tr("Current model: %1\nSet it with %2model MODEL").arg(Ai.getModel()?.name ?? Translation.tr("No model")).arg(root.commandPrefix)
                }

                ApiInputBoxIndicator {
                    icon: "service_toolbox"
                    text: Ai.currentTool.charAt(0).toUpperCase() + Ai.currentTool.slice(1)
                    tooltipText: Translation.tr("Current tool: %1\nSet it with %2tool TOOL").arg(Ai.currentTool).arg(root.commandPrefix)
                }

                Item {
                    Layout.fillWidth: true
                }

                ButtonGroup {
                    padding: 0

                    Repeater {
                        model: commandButtonsRow.commandsShown

                        delegate: ApiCommandButton {
                            property string commandRepresentation: `${root.commandPrefix}${modelData.name}`
                            buttonText: commandRepresentation

                            downAction: () => {
                                if (modelData.sendDirectly) {
                                    root.handleInput(commandRepresentation);
                                } else {
                                    messageInputField.text = commandRepresentation + (modelData.dontAddSpace ? "" : " ");
                                    messageInputField.cursorPosition = messageInputField.text.length;
                                    messageInputField.forceActiveFocus();
                                }

                                if (modelData.name === "clear") {
                                    messageInputField.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

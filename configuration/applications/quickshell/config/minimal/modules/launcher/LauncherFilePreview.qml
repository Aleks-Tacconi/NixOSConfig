pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "../../theme"

/**
 * Latest-request-wins preview for launcher files and clipboard entries.
 */
Item {
    id: root

    property var fileItem: null
    property string clipboardText: ""
    property string previewText: ""
    property string errorText: ""
    property bool loading: false
    property bool truncated: false
    property int generation: 0
    property bool decodeQueued: false
    property bool textQueued: false

    readonly property bool clipboardPreview: root.fileItem?.kind === "clipboard"
    readonly property bool binaryClipboard: root.clipboardPreview && ((root.fileItem?.raw ?? "").includes("[[ binary data") || (root.fileItem?.title ?? "").includes("[[ binary data"))
    readonly property string clipboardFilePath: root.filePathFromClipboard(root.clipboardText)
    readonly property string filePath: root.clipboardPreview ? root.clipboardFilePath : (root.fileItem?.path ?? "")
    readonly property string fileName: root.filePath.length > 0 ? (root.fileItem?.title ?? "File Preview") : "Copied Text"
    readonly property string extension: root.extensionFor(root.filePath)
    readonly property bool imagePreview: root.isImageExtension(root.extension)

    anchors.fill: parent

    onFileItemChanged: {
        root.generation += 1;
        root.clipboardText = "";
        root.previewText = "";
        root.errorText = "";
        root.loading = root.fileItem !== null;
        root.truncated = false;
        previewDelay.restart();
    }

    function extensionFor(path) {
        const dot = path.lastIndexOf(".");
        return dot >= 0 ? path.slice(dot + 1).toLowerCase() : "";
    }

    function isImageExtension(extension) {
        return ["avif", "bmp", "gif", "jpeg", "jpg", "png", "svg", "webp"].includes(extension);
    }

    function filePathFromClipboard(text) {
        const uri = (text.split("\n").find(line => line.startsWith("file://")) ?? "").replace(/\r$/, "");
        if (uri.length === 0)
            return "";
        const match = uri.match(/^file:\/\/([^/]*)(\/.*)$/);
        if (match === null || (match[1].length > 0 && match[1] !== "localhost"))
            return "";
        try {
            return decodeURIComponent(match[2]);
        } catch (error) {
            return "";
        }
    }

    function fileUri(path) {
        return `file://${encodeURIComponent(path).replace(/%2F/gi, "/")}`;
    }

    function startPreview(requestGeneration) {
        if (requestGeneration !== root.generation || root.fileItem === null)
            return;
        if (root.clipboardPreview) {
            if (root.binaryClipboard) {
                root.loading = false;
                root.errorText = "Binary clipboard data cannot be previewed";
                return;
            }
            root.startClipboardDecode(requestGeneration);
            return;
        }
        if (root.imagePreview) {
            root.loading = previewImage.status === Image.Loading;
            if (previewImage.status === Image.Error)
                root.errorText = "Image preview unavailable";
            return;
        }
        root.startTextPreview(requestGeneration, root.filePath);
    }

    function startClipboardDecode(requestGeneration) {
        if (clipboardDecodeProcess.running) {
            root.decodeQueued = true;
            return;
        }
        clipboardDecodeProcess.requestGeneration = requestGeneration;
        clipboardDecodeProcess.exec({
            command: ["sh", "-c", "printf %s \"$CLIPHIST_ENTRY\" | cliphist decode"],
            environment: ({
                    CLIPHIST_ENTRY: root.fileItem.raw
                })
        });
    }

    function applyClipboardText(text, requestGeneration) {
        if (requestGeneration !== root.generation)
            return;
        root.clipboardText = text;
        if (root.filePath.length === 0) {
            root.previewText = text;
            root.loading = false;
        } else if (root.imagePreview) {
            root.loading = previewImage.status === Image.Loading;
        } else {
            root.startTextPreview(requestGeneration, root.filePath);
        }
    }

    function startTextPreview(requestGeneration, path) {
        if (path.length === 0) {
            root.loading = false;
            root.errorText = "No preview available";
            return;
        }
        if (previewProcess.running) {
            root.textQueued = true;
            return;
        }
        previewProcess.requestGeneration = requestGeneration;
        previewProcess.exec({
            command: ["bash", "-lc", "if grep -Iq '' -- \"$FILE_PATH\" || [ ! -s \"$FILE_PATH\" ]; then\n  [ \"$(wc -c < \"$FILE_PATH\")\" -gt 16000 ] && printf truncated >&2\n  head -c 16000 -- \"$FILE_PATH\"\nelse\n  exit 2\nfi\n"],
            environment: ({
                    FILE_PATH: path
                })
        });
    }

    Timer {
        id: previewDelay

        interval: 80
        onTriggered: root.startPreview(root.generation)
    }

    Process {
        id: clipboardDecodeProcess

        property int requestGeneration: 0
        stdout: StdioCollector {
            id: clipboardOutput
        }
        stderr: StdioCollector {
            id: clipboardError
        }
        onExited: (exitCode, exitStatus) => {
            if (clipboardDecodeProcess.requestGeneration === root.generation) {
                if (exitCode === 0)
                    root.applyClipboardText(clipboardOutput.text, clipboardDecodeProcess.requestGeneration);
                else {
                    root.loading = false;
                    root.errorText = clipboardError.text.trim() || "Clipboard preview unavailable";
                }
            }
            if (root.decodeQueued) {
                root.decodeQueued = false;
                Qt.callLater(() => root.startPreview(root.generation));
            }
        }
    }

    Process {
        id: previewProcess

        property int requestGeneration: 0
        stdout: StdioCollector {
            id: previewOutput
        }
        stderr: StdioCollector {
            id: previewError
        }
        onExited: (exitCode, exitStatus) => {
            if (previewProcess.requestGeneration === root.generation) {
                root.loading = false;
                if (exitCode === 0) {
                    root.truncated = previewError.text.includes("truncated");
                    root.previewText = previewOutput.text;
                } else {
                    root.errorText = "No text preview available";
                }
            }
            if (root.textQueued) {
                root.textQueued = false;
                Qt.callLater(() => root.startPreview(root.generation));
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: Theme.panelItemGap

        Text {
            width: parent.width
            color: Theme.red
            elide: Text.ElideRight
            font.bold: true
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelTitleSize
            maximumLineCount: 1
            text: root.fileName
            textFormat: Text.PlainText
        }

        Text {
            width: parent.width
            color: Theme.muted
            elide: Text.ElideMiddle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelCaptionSize
            maximumLineCount: 1
            text: root.truncated ? "Preview truncated at 16 KB" : (root.fileItem?.subtitle ?? "")
            textFormat: Text.PlainText
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.popupInnerEdge
        }

        Rectangle {
            width: parent.width
            height: parent.height - y
            radius: Theme.surfaceRadius
            color: Theme.panelSurface
            clip: true

            Image {
                id: previewImage

                anchors.fill: parent
                anchors.margins: Theme.gap * 2
                visible: root.imagePreview && root.errorText.length === 0
                source: root.imagePreview ? root.fileUri(root.filePath) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                onStatusChanged: {
                    if (!root.imagePreview)
                        return;
                    root.loading = status === Image.Loading;
                    if (status === Image.Error)
                        root.errorText = "Image preview unavailable";
                }
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: Theme.gap * 2
                visible: !root.imagePreview && !root.loading && root.errorText.length === 0
                clip: true
                contentWidth: previewTextItem.width
                contentHeight: previewTextItem.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Text {
                    id: previewTextItem

                    width: parent.width
                    color: Theme.fg
                    font.family: "monospace"
                    font.pixelSize: Theme.panelCaptionSize
                    lineHeight: 1.25
                    text: root.previewText
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                }
            }

            Column {
                visible: root.loading || root.errorText.length > 0
                anchors.centerIn: parent
                width: parent.width - Theme.gap * 8
                spacing: Theme.gap * 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.loading ? "󰔟" : "󰅙"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 6
                }

                Text {
                    width: parent.width
                    text: root.loading ? "Loading preview..." : root.errorText
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelMetaSize
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "../../theme"

/**
 * Lightweight preview for selected launcher files.
 */
Item {
    id: root

    property var fileItem: null
    property string clipboardText: ""

    readonly property bool clipboardPreview: root.fileItem?.kind === "clipboard"
    readonly property string clipboardFilePath: root.filePathFromClipboard(root.clipboardText)
    readonly property string filePath: root.clipboardPreview ? root.clipboardFilePath : (root.fileItem?.path ?? "")
    readonly property string fileName: root.filePath.length > 0 ? (root.fileItem?.title ?? "File Preview") : "Copied Text"
    readonly property string extension: root.extensionFor(root.filePath)
    readonly property bool imagePreview: root.isImageExtension(root.extension)
    readonly property bool maybeTextPreview: (root.filePath.length > 0 || root.clipboardPreview) && !root.imagePreview

    function extensionFor(path) {
        const dot = path.lastIndexOf(".");

        return dot >= 0 ? path.slice(dot + 1).toLowerCase() : "";
    }

    function isImageExtension(extension) {
        return ["avif", "bmp", "gif", "jpeg", "jpg", "png", "svg", "webp"].includes(extension);
    }

    function filePathFromClipboard(text) {
        const uri = text.split("\n").find(line => line.startsWith("file://")) ?? "";

        return uri.length > 0 ? decodeURIComponent(uri.replace(/^file:\/\//, "")) : "";
    }

    function refreshTextPreview() {
        if (root.clipboardPreview && root.filePath.length === 0) {
            previewText.text = root.clipboardText;
            return;
        }

        previewProcess.exec({
            command: ["bash", "-lc", "if grep -Iq . -- \"$FILE_PATH\" || [ ! -s \"$FILE_PATH\" ]; then\n  head -c 16000 -- \"$FILE_PATH\"\nelse\n  printf 'No preview available for this file'\nfi\n"],
            environment: ({
                    FILE_PATH: root.filePath
                })
        });
    }

    anchors.fill: parent

    onFilePathChanged: {
        previewText.text = "";
        if (root.maybeTextPreview)
            root.refreshTextPreview();
    }

    onFileItemChanged: {
        root.clipboardText = "";
        previewText.text = "";

        if (root.clipboardPreview && root.fileItem?.raw) {
            clipboardDecodeProcess.exec({
                command: ["sh", "-c", "printf %s \"$CLIPHIST_ENTRY\" | cliphist decode"],
                environment: ({
                        CLIPHIST_ENTRY: root.fileItem.raw
                    })
            });
        }
    }

    onClipboardTextChanged: {
        previewText.text = "";
        if (root.maybeTextPreview)
            root.refreshTextPreview();
    }

    Process {
        id: clipboardDecodeProcess

        stdout: StdioCollector {
            onStreamFinished: root.clipboardText = text
        }
    }

    Process {
        id: previewProcess

        stdout: StdioCollector {
            onStreamFinished: previewText.text = text
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
        }

        Text {
            width: parent.width
            color: Theme.muted
            elide: Text.ElideMiddle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelCaptionSize
            maximumLineCount: 1
            text: root.fileItem?.subtitle ?? ""
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
                anchors.fill: parent
                anchors.margins: Theme.gap * 2
                visible: root.imagePreview
                source: root.imagePreview ? encodeURI(`file://${root.filePath}`) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: Theme.gap * 2
                visible: !root.imagePreview
                clip: true
                contentWidth: previewText.width
                contentHeight: previewText.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Text {
                    id: previewText

                    width: parent.width
                    color: Theme.fg
                    font.family: "monospace"
                    font.pixelSize: Theme.panelCaptionSize
                    lineHeight: 1.25
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}

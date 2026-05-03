pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions as CF
import qs.modules.common
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.services.ai

/**
 * Basic service to handle local LLM chats.
 * Models are discovered from Ollama and optional local OpenAI-compatible endpoints.
 */
Singleton {
    id: root

    property Component aiMessageComponent: AiMessageData {}
    property Component aiModelComponent: AiModel {}
    property Component openaiApiStrategy: OpenAiApiStrategy {}
    readonly property string interfaceRole: "interface"

    signal responseFinished()

    property string systemPrompt: {
        let prompt = Config.options?.ai?.systemPrompt ?? "";
        for (let key in root.promptSubstitutions) {
            prompt = prompt.split(key).join(root.promptSubstitutions[key]);
        }
        return prompt;
    }

    property var messageIDs: []
    property var messageByID: ({})
    property var postResponseHook
    property real temperature: Persistent.states?.ai?.temperature ?? 0.5

    property QtObject tokenCount: QtObject {
        property int input: -1
        property int output: -1
        property int total: -1
    }

    function idForMessage(message) {
        return Date.now().toString(36) + Math.random().toString(36).substr(2, 8);
    }

    function safeModelName(modelName) {
        return modelName.replace(/:/g, "_").replace(/ /g, "-").replace(/\//g, "-");
    }

    property var promptSubstitutions: {
        "{DISTRO}": SystemInfo.distroName,
        "{DATETIME}": `${DateTime.time}, ${DateTime.collapsedCalendarFormat}`,
        "{WINDOWCLASS}": ToplevelManager.activeToplevel?.appId ?? "Unknown",
        "{DE}": `${SystemInfo.desktopEnvironment} (${SystemInfo.windowingSystem})`
    }

    property string currentTool: Config?.options.ai.tool ?? "none"

    property var tools: {
        "openai": {
            "search": [],
            "none": [],
        }
    }

    property list<var> availableTools: Object.keys(root.tools[models[currentModelId]?.api_format || "openai"])

    property var toolDescriptions: {
        "search": Translation.tr("No live search backend is configured in this sidebar"),
        "none": Translation.tr("Disable tools")
    }

    property var models: ({})
    property var modelList: Object.keys(root.models)
    property var currentModelId: Persistent.states?.ai?.model || modelList[0]

    property var apiStrategies: {
        "openai": openaiApiStrategy.createObject(this)
    }

    property ApiStrategy currentApiStrategy: apiStrategies[models[currentModelId]?.api_format || "openai"]

    function isLocalEndpoint(endpoint) {
        return /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(?::\d+)?\//.test(endpoint ?? "");
    }

    function addUserModels() {
        (Config?.options.ai?.extraModels ?? []).forEach(model => {
            if (!root.isLocalEndpoint(model.endpoint)) return;
            const safeModelName = root.safeModelName(model["model"]);
            root.addModel(safeModelName, model);
        });
    }

    Connections {
        target: Config

        function onReadyChanged() {
            if (!Config.ready) return;
            root.addUserModels();
        }
    }

    property string requestScriptFilePath: "/tmp/quickshell/ai/request.sh"
    property string pendingFilePath: ""

    Component.onCompleted: {
        root.addUserModels();
    }

    function guessModelLogo(model) {
        if (model.includes("llama")) return "ollama-symbolic";
        if (model.includes("deepseek")) return "deepseek-symbolic";
        if (/^phi\d*:/i.test(model)) return "microsoft-symbolic";
        return "ollama-symbolic";
    }

    function guessModelName(model) {
        const replaced = model.replace(/-/g, " ").replace(/:/g, " ");
        let words = replaced.split(" ");

        words[words.length - 1] = words[words.length - 1].replace(/(\d+)b$/, (_, num) => `${num}B`);

        words = words.map(word => {
            return word.charAt(0).toUpperCase() + word.slice(1);
        });

        if (words[words.length - 1] === "Latest") {
            words.pop();
        } else {
            words[words.length - 1] = `(${words[words.length - 1]})`;
        }

        return words.join(" ");
    }

    function addModel(modelName, data) {
        root.models = Object.assign({}, root.models, {
            [modelName]: aiModelComponent.createObject(this, data)
        });
    }

    Process {
        id: getOllamaModels
        running: true
        command: ["bash", "-c", `${Directories.scriptPath}/ai/show-installed-ollama-models.sh`.replace(/file:\/\//, "")]

        stdout: SplitParser {
            onRead: data => {
                try {
                    if (data.length === 0) return;

                    const dataJson = JSON.parse(data);
                    root.modelList = [...root.modelList, ...dataJson];

                    dataJson.forEach(model => {
                        const safeModelName = root.safeModelName(model);

                        root.addModel(safeModelName, {
                            "name": guessModelName(model),
                            "icon": guessModelLogo(model),
                            "description": Translation.tr("Local Ollama model | %1").arg(model),
                            "homepage": `https://ollama.com/library/${model}`,
                            "endpoint": "http://localhost:11434/v1/chat/completions",
                            "model": model,
                        });
                    });

                    root.modelList = Object.keys(root.models);

                    if (root.modelList.length > 0 && root.modelList.indexOf(root.currentModelId) === -1) {
                        root.setModel(root.modelList[0], false);
                    }
                } catch (e) {
                    console.log("Could not fetch Ollama models:", e);
                }
            }
        }
    }

    function addMessage(message, role) {
        if (!message || message.length === 0) return;

        const aiMessage = aiMessageComponent.createObject(root, {
            "role": role,
            "content": message,
            "rawContent": message,
            "thinking": false,
            "done": true,
        });

        const id = idForMessage(aiMessage);

        root.messageByID = Object.assign({}, root.messageByID, {
            [id]: aiMessage,
        });

        root.messageIDs = [...root.messageIDs, id];
    }

    function removeMessage(index) {
        if (index < 0 || index >= messageIDs.length) return;

        const id = root.messageIDs[index];

        root.messageIDs.splice(index, 1);
        root.messageIDs = [...root.messageIDs];

        const updatedMessages = Object.assign({}, root.messageByID);
        delete updatedMessages[id];

        root.messageByID = updatedMessages;
    }

    function getModel() {
        return models[currentModelId];
    }

    function setModel(modelId, feedback = true, setPersistentState = true) {
        if (!modelId) modelId = "";

        modelId = modelId.toLowerCase();

        if (modelList.indexOf(modelId) !== -1) {
            const model = models[modelId];

            root.currentModelId = modelId;

            if (setPersistentState) {
                Persistent.states.ai.model = modelId;
            }

            if (feedback) {
                root.addMessage(Translation.tr("Model set to %1").arg(model.name), root.interfaceRole);
            }
        } else {
            if (feedback) {
                root.addMessage(Translation.tr("Invalid model. Supported: \n```\n") + modelList.join("\n```\n```\n") + "\n```", root.interfaceRole);
            }
        }
    }

    function setTool(tool) {
        const apiFormat = models[currentModelId]?.api_format || "openai";

        if (!root.tools[apiFormat] || !(tool in root.tools[apiFormat])) {
            root.addMessage(Translation.tr("Invalid tool. Supported tools:\n- %1").arg(root.availableTools.join("\n- ")), root.interfaceRole);
            return false;
        }

        Config.options.ai.tool = tool;
        return true;
    }

    function getTemperature() {
        return root.temperature;
    }

    function clearMessages() {
        if (requester.running) {
            requester.running = false;
        }

        root.pendingFilePath = "";
        root.postResponseHook = null;
        root.currentApiStrategy.reset();
        root.messageIDs = [];
        root.messageByID = ({});
        root.tokenCount.input = -1;
        root.tokenCount.output = -1;
        root.tokenCount.total = -1;
        root.saveChat("lastSession");
    }

    FileView {
        id: requesterScriptFile
    }

    Process {
        id: requester

        property list<string> baseCommand: ["bash"]
        property AiMessageData message
        property ApiStrategy currentStrategy

        function markDone() {
            requester.message.done = true;

            if (root.postResponseHook) {
                root.postResponseHook();
                root.postResponseHook = null;
            }

            root.saveChat("lastSession");
            root.responseFinished();
        }

        function makeRequest() {
            const model = models[currentModelId];

            if (!model) {
                root.addMessage(Translation.tr("No local models available. Install an Ollama model first."), root.interfaceRole);
                return;
            }

            if (requester.running) {
                requester.running = false;
            }

            const apiFormat = model.api_format || "openai";

            requester.currentStrategy = root.currentApiStrategy;
            requester.currentStrategy.reset();

            const endpoint = requester.currentStrategy.buildEndpoint(model);

            const messageArray = root.messageIDs.map(id => root.messageByID[id]);

            const filteredMessageArray = messageArray.filter(message => {
                if (!message) return false;
                if (message.role === root.interfaceRole) return false;
                if (message.role === "assistant" && message.done === false) return false;
                return true;
            });

            const data = requester.currentStrategy.buildRequestData(
                model,
                filteredMessageArray,
                root.systemPrompt,
                root.temperature,
                root.tools[apiFormat][root.currentTool],
                root.pendingFilePath
            );

            let requestHeaders = {
                "Content-Type": "application/json",
            };

            requester.message = root.aiMessageComponent.createObject(root, {
                "role": "assistant",
                "model": currentModelId,
                "content": "",
                "rawContent": "",
                "thinking": true,
                "done": false,
            });

            const id = idForMessage(requester.message);

            root.messageByID = Object.assign({}, root.messageByID, {
                [id]: requester.message,
            });

            root.messageIDs = [...root.messageIDs, id];

            let headerString = Object.entries(requestHeaders)
                .filter(([k, v]) => v && v.length > 0)
                .map(([k, v]) => `-H '${k}: ${v}'`)
                .join(" ");

            const scriptShebang = "#!/usr/bin/env bash\n";

            let scriptFileSetupContent = "";

            if (root.pendingFilePath && root.pendingFilePath.length > 0) {
                requester.message.localFilePath = root.pendingFilePath;
                scriptFileSetupContent = requester.currentStrategy.buildScriptFileSetup(root.pendingFilePath);
                root.pendingFilePath = "";
            }

            let scriptRequestContent = "";

            scriptRequestContent += `curl --no-buffer "${endpoint}"`
                + ` ${headerString}`
                + ` --data '${CF.StringUtils.shellSingleQuoteEscape(JSON.stringify(data))}'`
                + "\n";

            const scriptContent = requester.currentStrategy.finalizeScriptContent(
                scriptShebang + scriptFileSetupContent + scriptRequestContent
            );

            // Important:
            // Do not write to /tmp/request.sh and immediately execute it.
            // FileView.setText can race, causing the previous request body to run.
            // That makes the model answer one message behind.
            requester.command = requester.baseCommand.concat(["-c", scriptContent]);
            requester.running = true;
        }

        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0) return;

                if (requester.message.thinking) {
                    requester.message.thinking = false;
                }

                try {
                    const result = requester.currentStrategy.parseResponseLine(data, requester.message);

                    if (result.functionCall) {
                        requester.message.functionCall = result.functionCall;
                        root.handleFunctionCall(result.functionCall.name, result.functionCall.args, requester.message);
                    }

                    if (result.tokenUsage) {
                        root.tokenCount.input = result.tokenUsage.input;
                        root.tokenCount.output = result.tokenUsage.output;
                        root.tokenCount.total = result.tokenUsage.total;
                    }

                    if (result.finished) {
                        requester.markDone();
                    }
                } catch (e) {
                    console.log("[AI] Could not parse response: ", e);
                    requester.message.rawContent += data;
                    requester.message.content += data;
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            const result = requester.currentStrategy.onRequestFinished(requester.message);

            if (result.finished) {
                requester.markDone();
            } else if (!requester.message.done) {
                requester.markDone();
            }
        }
    }

    function cancelInFlightRequest() {
        if (!requester.running) return;

        requester.running = false;
        root.postResponseHook = null;

        for (let i = root.messageIDs.length - 1; i >= 0; i--) {
            const id = root.messageIDs[i];
            const msg = root.messageByID[id];

            if (msg && msg.role === "assistant" && msg.done === false) {
                root.removeMessage(i);
                break;
            }
        }
    }

    function sendUserMessage(message) {
        const cleanMessage = (message ?? "").trim();

        if (cleanMessage.length === 0) {
            return;
        }

        cancelInFlightRequest();

        root.addMessage(cleanMessage, "user");

        Qt.callLater(() => {
            requester.makeRequest();
        });
    }

    function attachFile(filePath: string) {
        root.pendingFilePath = CF.FileUtils.trimFileProtocol(filePath);
    }

    function regenerate(messageIndex) {
        if (messageIndex < 0 || messageIndex >= messageIDs.length) return;

        const id = root.messageIDs[messageIndex];
        const message = root.messageByID[id];

        if (message.role !== "assistant") return;

        for (let i = root.messageIDs.length - 1; i >= messageIndex; i--) {
            root.removeMessage(i);
        }

        Qt.callLater(() => {
            requester.makeRequest();
        });
    }

    function createFunctionOutputMessage(name, output, includeOutputInChat = true) {
        return aiMessageComponent.createObject(root, {
            "role": "user",
            "content": `[[ Output of ${name} ]]${includeOutputInChat ? ("\n\n<think>\n" + output + "\n</think>") : ""}`,
            "rawContent": `[[ Output of ${name} ]]${includeOutputInChat ? ("\n\n<think>\n" + output + "\n</think>") : ""}`,
            "functionName": name,
            "functionResponse": output,
            "thinking": false,
            "done": true,
        });
    }

    function addFunctionOutputMessage(name, output) {
        const aiMessage = createFunctionOutputMessage(name, output);
        const id = idForMessage(aiMessage);

        root.messageByID = Object.assign({}, root.messageByID, {
            [id]: aiMessage,
        });

        root.messageIDs = [...root.messageIDs, id];
    }

    function rejectCommand(message: AiMessageData) {
        if (!message.functionPending) return;

        message.functionPending = false;
        addFunctionOutputMessage(message.functionName, Translation.tr("Command rejected by user"));
    }

    function approveCommand(message: AiMessageData) {
        if (!message.functionPending) return;

        message.functionPending = false;

        const responseMessage = createFunctionOutputMessage(message.functionName, "", false);
        const id = idForMessage(responseMessage);

        root.messageByID = Object.assign({}, root.messageByID, {
            [id]: responseMessage,
        });

        root.messageIDs = [...root.messageIDs, id];

        commandExecutionProc.message = responseMessage;
        commandExecutionProc.baseMessageContent = responseMessage.content;
        commandExecutionProc.shellCommand = message.functionCall.args.command;
        commandExecutionProc.running = true;
    }

    Process {
        id: commandExecutionProc

        property string shellCommand: ""
        property AiMessageData message
        property string baseMessageContent: ""

        command: ["bash", "-c", shellCommand]

        stdout: SplitParser {
            onRead: output => {
                commandExecutionProc.message.functionResponse += output + "\n\n";

                const updatedContent = commandExecutionProc.baseMessageContent
                    + `\n\n<think>\n<tt>${commandExecutionProc.message.functionResponse}</tt>\n</think>`;

                commandExecutionProc.message.rawContent = updatedContent;
                commandExecutionProc.message.content = updatedContent;
            }
        }

        onExited: (exitCode, exitStatus) => {
            commandExecutionProc.message.functionResponse += `[[ Command exited with code ${exitCode} (${exitStatus}) ]]\n`;

            Qt.callLater(() => {
                requester.makeRequest();
            });
        }
    }

    function handleFunctionCall(name, args: var, message: AiMessageData) {
        if (name === "switch_to_search_mode") {
            addFunctionOutputMessage(name, Translation.tr("Switched to search mode. Continue with the user's request."));

            Qt.callLater(() => {
                requester.makeRequest();
            });
        } else if (name === "get_shell_config") {
            const configJson = CF.ObjectUtils.toPlainObject(Config.options);

            addFunctionOutputMessage(name, JSON.stringify(configJson));

            Qt.callLater(() => {
                requester.makeRequest();
            });
        } else if (name === "set_shell_config") {
            if (!args.key || !args.value) {
                addFunctionOutputMessage(name, Translation.tr("Invalid arguments. Must provide `key` and `value`."));
                return;
            }

            const key = args.key;
            const value = args.value;

            Config.setNestedValue(key, value);
        } else if (name === "run_shell_command") {
            if (!args.command || args.command.length === 0) {
                addFunctionOutputMessage(name, Translation.tr("Invalid arguments. Must provide `command`."));
                return;
            }

            const contentToAppend = `\n\n**Command execution request**\n\n\`\`\`command\n${args.command}\n\`\`\``;

            message.rawContent += contentToAppend;
            message.content += contentToAppend;
            message.functionPending = true;
        } else {
            root.addMessage(Translation.tr("Unknown function call: %1").arg(name), "assistant");
        }
    }

    function chatToJson() {
        return root.messageIDs.map(id => {
            const message = root.messageByID[id];

            return ({
                "role": message.role,
                "rawContent": message.rawContent,
                "fileMimeType": message.fileMimeType,
                "fileUri": message.fileUri,
                "localFilePath": message.localFilePath,
                "model": message.model,
                "thinking": false,
                "done": true,
                "annotations": message.annotations,
                "annotationSources": message.annotationSources,
                "functionName": message.functionName,
                "functionCall": message.functionCall,
                "functionResponse": message.functionResponse,
                "visibleToUser": message.visibleToUser,
            });
        });
    }

    FileView {
        id: chatSaveFile
        property string chatName: ""
        path: chatName.length > 0 ? `${Directories.aiChats}/${chatName}.json` : ""
        blockLoading: true
    }

    function saveChat(chatName) {
        chatSaveFile.chatName = chatName.trim();

        const saveContent = JSON.stringify(root.chatToJson());

        chatSaveFile.setText(saveContent);
    }
}

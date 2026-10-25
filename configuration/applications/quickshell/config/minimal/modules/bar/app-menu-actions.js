/** Pure application identity and menu action transformations. */

/** Freeze window identity for asynchronous requests. */
function snapshotIpcWindow(window) {
    return Object.freeze({
        address: String(window?.address ?? ""),
        pid: Number(window?.pid ?? 0),
        class: String(window?.class ?? ""),
        title: String(window?.title ?? ""),
        workspace: Object.freeze({
            id: Number(window?.workspace?.id ?? 0),
            name: String(window?.workspace?.name ?? "")
        })
    });
}

/** Normalize desktop IDs and window classes for matching. */
function normalizedAppId(value) {
    return String(value ?? "")
        .toLowerCase()
        .replace(/\.desktop$/, "")
        .replace(/[^a-z0-9]+/g, "");
}

/** Match a compositor window to the requested application. */
function ipcMatchesApp(window, appId) {
    if (Number(window?.pid ?? 0) <= 0)
        return false;

    const windowClass = normalizedAppId(window?.class);
    const windowInitialClass = normalizedAppId(window?.initialClass);
    const applicationId = normalizedAppId(appId);
    if (applicationId.length === 0)
        return windowClass.length > 0;

    return (windowClass.length > 0
        && (windowClass === applicationId
            || windowClass.endsWith(applicationId)
            || applicationId.endsWith(windowClass)))
        || (windowInitialClass.length > 0
            && (windowInitialClass === applicationId
                || windowInitialClass.endsWith(applicationId)
                || applicationId.endsWith(windowInitialClass)));
}

/** Read the application ID used for menu requests. */
function toplevelAppId(target) {
    const appId = String(target?.appId ?? "");
    return appId.length > 0 ? appId : "Application";
}

/** Recognize equivalent new-window actions. */
function isNewWindowActionTitle(title) {
    const key = String(title ?? "").trim().toLowerCase();
    return key === "new window"
        || key === "new-window"
        || key === "open a new window"
        || key === "new empty window"
        || key === "new instance";
}

/** Snapshot desktop actions before asynchronous resolution. */
function copyDesktopActions(actions) {
    const copy = [];
    for (let index = 0; index < (actions?.length ?? 0); index++) {
        copy.push(actions[index]);
    }
    return Object.freeze(copy);
}

/** Create a display name from an application ID. */
function friendlyName(appId) {
    const shortName = appId.split(".").pop() || "Application";
    const spaced = shortName
        .replace(/[-_]+/g, " ")
        .replace(/([a-z0-9])([A-Z])/g, "$1 $2");

    return spaced.replace(/\b\w/g, letter => letter.toUpperCase());
}

/** Normalize action labels for deduplication. */
function actionKey(value) {
    return String(value ?? "").toLowerCase().replace(/[^a-z0-9]+/g, "");
}

/** Build comparable keys from a label and action ID. */
function actionKeys(title, actionId) {
    const shortId = String(actionId ?? "").split(".").pop();
    return [actionKey(title), actionKey(shortId)].filter(key => key.length > 0);
}

/** Choose a glyph for an application action. */
function actionGlyph(title) {
    const key = actionKey(title);
    if (key.includes("incognito") || key.includes("private"))
        return "";
    if (key.includes("new") || key === "open")
        return "󰐕";
    if (key.includes("search") || key.includes("find"))
        return "";
    if (key.includes("copy"))
        return "";
    if (key.includes("paste"))
        return "";
    if (key.includes("cut"))
        return "";
    if (key.includes("save"))
        return "";
    if (key.includes("print"))
        return "";
    if (key.includes("settings") || key.includes("preferences"))
        return "";
    if (key.includes("refresh") || key.includes("reload"))
        return "󰑐";
    if (key.includes("edit"))
        return "";
    if (key.includes("view"))
        return "";
    if (key.includes("help") || key.includes("about"))
        return "";
    if (key.includes("quit") || key.includes("exit") || key.includes("logout"))
        return "󰍃";

    return "";
}

/** Combine desktop and GTK actions without duplicates. */
function combineActions(desktopActions, gtkActions) {
    const combined = [];
    const seen = [];

    for (let index = 0; index < desktopActions.length; index++) {
        const desktopAction = desktopActions[index];
        const title = String(desktopAction.name ?? "").trim();
        if (title.length === 0)
            continue;

        const keys = actionKeys(title, "");
        combined.push(Object.freeze({
            kind: "desktop",
            title: title,
            desktopAction: desktopAction
        }));
        seen.push(...keys);
    }

    for (const gtkAction of gtkActions) {
        const keys = actionKeys(gtkAction.title, gtkAction.action);
        if (keys.some(key => seen.includes(key)))
            continue;

        combined.push(Object.freeze({
            kind: "gtk",
            title: gtkAction.title,
            gtkAction: gtkAction
        }));
        seen.push(...keys);
    }

    return Object.freeze(combined);
}

/** Validate GTK action payloads before displaying them. */
function parseGtkActions(output) {
    try {
        const actions = JSON.parse(output);
        if (!Array.isArray(actions))
            return null;

        const parsed = [];
        for (const action of actions) {
            if (action === null
                    || typeof action.service !== "string" || action.service.length === 0
                    || typeof action.path !== "string" || !action.path.startsWith("/")
                    || typeof action.action !== "string" || action.action.length === 0
                    || typeof action.title !== "string" || action.title.length === 0)
                return null;

            parsed.push(Object.freeze({
                service: action.service,
                path: action.path,
                action: action.action,
                title: action.title
            }));
        }
        return Object.freeze(parsed);
    } catch (error) {
        return null;
    }
}

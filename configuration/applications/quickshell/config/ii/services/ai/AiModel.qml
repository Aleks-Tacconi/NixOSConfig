import QtQuick;

/**
 * An AI model representation.
 * - name: Friendly name of the model
 * - icon: Icon name of the model
 * - description: Description of the model
 * - endpoint: Endpoint of the model
 * - model: Model code (like llama3.2 or qwen2.5)
 * - api_format: The API format of the model. Default is "openai".
 * - extraParams: Extra parameters to be passed to the model. This is a JSON object.
 */

QtObject {
    property string name
    property string icon
    property string description
    property string homepage
    property string endpoint
    property string model
    property string api_format: "openai"
    property var tools
    property var extraParams: ({})
}

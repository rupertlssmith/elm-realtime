export function checkPortsExist(app: any, portNames: string[]) {
    if (!app.ports) {
        throw "The Elm application has no ports.";
    }

    for (let i = 0; i < portNames.length; i++) {
        const portName = portNames[i];

        // eslint-disable-next-line no-prototype-builtins
        if (!app.ports.hasOwnProperty(portName)) {
            throw "Could not find a port named: " + portName;
        }
    }
}

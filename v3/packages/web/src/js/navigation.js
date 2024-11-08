// Listens to pointer events on the document.

class Navigation {
    constructor(app) {
        this.app = app;

        this.popStateCallback = this.popStateCallback.bind(this);

        window.addEventListener("popstate", this.popStateCallback);

        // Change the URL upon request, inform app of the change.
        if (app.ports.pushUrl) {
            app.ports.pushUrl.subscribe(function (url) {
                history.pushState({}, '', url);
                app.ports.onUrlChange.send(location.href);
            })
        }
    }

    popStateCallback(e) {
        this.app.ports.onUrlChange.send(location.href);
    }
}

module.exports = Navigation;

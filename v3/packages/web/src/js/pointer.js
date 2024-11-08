// Listens to pointer events on the document.

class Pointer {
    constructor(app) {
        this.app = app;

        this.pointerDownCallback = this.pointerDownCallback.bind(this);
        this.pointerUpCallback = this.pointerUpCallback.bind(this);
        this.pointerMoveCallback = this.pointerMoveCallback.bind(this);
        this.pointerCancelCallback = this.pointerCancelCallback.bind(this);

        document.addEventListener("pointerdown", this.pointerDownCallback);
        document.addEventListener("pointerup", this.pointerUpCallback);
        document.addEventListener("pointermove", this.pointerMoveCallback);
        document.addEventListener("pointercancel", this.pointerCancelCallback);
    }

    pointerDownCallback(e) {
        if (this.app.ports.onPointerDown) {
            this.app.ports.onPointerDown.send(e);
        }
    }

    pointerUpCallback(e) {
        if (this.app.ports.onPointerUp) {
            this.app.ports.onPointerUp.send(e);
        }
    }

    pointerMoveCallback(e) {
        if (this.app.ports.onPointerMove) {
            this.app.ports.onPointerMove.send(e);
        }
    }

    pointerCancelCallback(e) {
        if (this.app.ports.onPointerCancel) {
            this.app.ports.onPointerCancel.send(e);
        }
    }
}

module.exports = Pointer;

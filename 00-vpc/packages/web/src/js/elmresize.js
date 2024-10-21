// Wraps a ResizeObserver in a custom element that can be wrapped around some Html 
// in an Elm view, in order to be able to receive resize events from it.
// 
// The event is called 'resize' and provides 'w' and 'h' values in the event details 
// giving the new size in pixels.
class Resizeable extends HTMLElement {
    constructor() {
        super();

        this.resizeCallback = this.resizeCallback.bind(this);
        this._observer = new ResizeObserver(this.resizeCallback);
    }

    connectedCallback() {
        this._observer.observe(this);
    }

    disconnectedCallback() {
        this._observer.disconnect();
    }

    resizeCallback(e) {
        for (let entry of e) {
            if (entry.borderBoxSize) {
                // Firefox implements as a single content rect, rather than an array
                const borderBoxSize = Array.isArray(entry.borderBoxSize) ? entry.borderBoxSize[0] : entry.borderBoxSize;

                let event = new CustomEvent("resize", {
                    detail: {
                        w: borderBoxSize.inlineSize,
                        h: borderBoxSize.blockSize
                    }
                });

                this.dispatchEvent(event);
            }
        }
    }
}

customElements.define('elm-resize', Resizeable);

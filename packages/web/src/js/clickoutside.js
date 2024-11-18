class ClickOutside extends HTMLElement {

    constructor() {
        super();
    }

    static get observedAttributes() {
        return []
    }

    connectedCallback() {
        this.element = this;
        this.mouseEventListener = this.startClick.bind(this);
        document.addEventListener("mousedown", this.mouseEventListener);
    }

    startClick(e) {
        console.log("startclick");
        this.clickTarget = e.target;
        document.addEventListener("mouseup", this.endClick.bind(this), {once: true});
    }

    endClick(e) {
        console.log("endclick");
        // Outside click has to both start and end outside of our element
        if (!isInside(this, this.clickTarget) && !isInside(this, e.target)) {
            let event = new CustomEvent('clickoutside', {bubbles: false, detail: {}});
            this.dispatchEvent(event);
        }
    }

    disconnectedCallback() {
        // Clean up eventlistener when DOM node is removed
        document.removeEventListener("mousedown", this.mouseEventListener)
    }
}

function isInside(parent, child) {
    var target = child;
    while (target && target != parent) {
        target = target.parentNode;
    }

    return target == parent;
}

window.customElements.define("click-outside", ClickOutside);

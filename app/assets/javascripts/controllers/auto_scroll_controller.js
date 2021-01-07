import { Controller } from "stimulus"

export default class extends Controller {
    const 
    initialize() {
        const mutObserver = new MutationObserver(this.observe(this));
        mutObserver.observe(this.element, { childList: true, });
        this.flow();
    }
    observe(observed) {
        return function(muts) {
            muts.forEach(function(mut) {
                if (mut.addedNodes && mut.addedNodes.length > 0)
                    observed.flow();
            });
        };
    }
    flow() {
        if (this.element)
            this.element.scrollTop += this.element.scrollHeight;
    }
}
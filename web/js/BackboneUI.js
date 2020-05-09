// All backbone objects are observers so we only need to create a generic observable
var EventList = {
    OBSERVE_CHANGE: "observedChange", // Args: observable, oldValue, newValue
    BUTTON_CLICKED: "buttonClick", //TODO: What arguments should be passed?
};

var ObservableNames = {
    OBJECT: "object",
    //--------
    HREF: "a_href",
    VALUE: "attr-value",
    TEXT: "html-innerText",
};

var Observable = function(value){
    this.object = value; // Don't use setValue so as to avoid triggering a change event on init

    this.setValue = function(newValue){
        var oldValue = this.getValue();
        this.object = newValue;
        this.trigger(EventList.OBSERVE_CHANGE, oldValue, newValue);
    };

    this.getValue = function(){
        return this.object;
    };
    _.extend(this, Backbone.Events);
};

var ObservableView = Backbone.View.extend({
    _observableAttrib_: [ObservableNames.OBJECT],
    initialize: function(properties){
        this.observables = {};

        if(!properties){
            properties = {};
        }

        var self = this;
        this._observableAttrib_.forEach(function(item, index){
            if (properties[item]){
                // We default to creating observable objects
                self.setValue(properties[item], item);
            }
        });
    },
    getValue: function(valueName){
        if(!valueName){
            valueName = ObservableNames.OBJECT;
        }

        // This function is for getting a property value regardless of whether it is a property
        var prop = this.observables[valueName];
        if(!(prop instanceof Observable)){
            return prop;
        }
        return prop.getValue();
    },
    setValue: function(newValue, valueName){
        if(newValue instanceof Observable){
            this.setRawValue(newValue, valueName);
        } else {
            var observable = this.getObservable(valueName);
            if (observable != null){
                observable.setValue(newValue);
            } else {
                // If we set a property with this function it converts it to an observable
                // should that be undesired use setRawValue instead
                var observ = new Observable(newValue);
                this.setRawValue(observ, valueName);

                // Now we trigger the event that would normally fire if the observable had already existed
                observ.trigger(EventList.OBSERVE_CHANGE, undefined, newValue);
            }
        }
    },
    setRawValue: function(newValue, valueName){
        if(!valueName){
            valueName = ObservableNames.OBJECT;
        }

        var oldObserve = this.getObservable(valueName);
        if (oldObserve != null){
            this.stopListening(oldObserve);
        }

        if(newValue instanceof Observable){
            this.listenTo(newValue, EventList.OBSERVE_CHANGE, function(){
                this.onObservedChange(newValue, valueName);
            });
        }

        this.observables[valueName] = newValue;
    },
    getObservable: function(propertyName){
        // This function is for getting the observable of a property and will return null for non observables
        var prop = this.observables[propertyName];
        if(prop instanceof Observable){
            return prop;
        }
        return null;
    },
    /*makeObservable: function(propertyName){
        var observable = this.getObservable(propertyName);
        if (observable == null){
            var value = this.getValue(propertyName);
            this.setRawValue(new Observable(value), propertyName);
        }
        // Else do nothing bc the property is already an observable
    },*/
    onObservedChange: function(observable, observedProperty){
        this.render();  // Default is to render
    },
});

var ViewContainer = Backbone.View.extend({
    views: null,
    tagName: "div",
    initialize: function(element){
        this.views = [];
        if(element){
            this.setElement(element);
        }
    },
    render: function(){
        var self = this;
        console.log("ViewContainer.render");
        this.$el.empty(); // TODO: I don't like the erase and reset model, fix it
        this.views.forEach(function(item){
            item.render();
            self.$el.append(item.$el);
        })
    },
    addView: function(view){
        this.views.push(view);
    },

    //TODO: Add a way to remove views and possibly to get specific views by name
});

var TextView = ObservableView.extend({
    tagName: "p",
    _observableAttrib_: [...ObservableView.prototype._observableAttrib_, ObservableNames.TEXT],
    initialize: function(attributes){
        ObservableView.prototype.initialize.apply(this, [attributes]);
    },
    render: function(){
        this.$el.text(this.getText());
    },
    //----------------------------------------
    setText: function(newText){
        // TODO: newText must be a string
        this.setValue(newText, ObservableNames.TEXT);
    },
    getText: function(){
        // TODO: this must return the value and not the reference
        return this.getValue(ObservableNames.TEXT);
    },
});
var LinkView = TextView.extend({
    tagName: "a",
    _observableAttrib_: [...TextView.prototype._observableAttrib_, ObservableNames.HREF],
    initialize: function(attributes){
        TextView.prototype.initialize.apply(this, [attributes]);
    },
    render: function(){
        this.$el.attr("href", this.getHref());
        TextView.prototype.render.apply(this);
    },
    //----------------------------------------
    setHref: function(newText){
        // TODO: newText must be a string
        this.setValue(newText, ObservableNames.HREF);
    },
    getHref: function(){
        // TODO: this must return the value and not the reference
        return this.getValue(ObservableNames.HREF);
    },
});
var ButtonView = TextView.extend({
    tagName: "button",
    initialize: function(onClick, attributes){
        TextView.prototype.initialize.apply(this, [attributes]);
        this.clickHandler = onClick;
    },
    events: {
        "click" : "onClick",
    },
    onClick: function(){
        //TODO: What arguments should be passed?
        this.clickHandler();
        this.trigger(EventList.BUTTON_CLICKED);
    },
});
var ProgressView = ObservableView.extend({
    tagName: "progress",
    _observableAttrib_: [...ObservableView.prototype._observableAttrib_, ObservableNames.VALUE],
    initialize: function(attributes){
        ObservableView.prototype.initialize.apply(this, [attributes]);
    },
    render: function(){
        this.$el.attr("value", this.getProgress());
    },
    //----------------------------------------
    setProgress: function(newValue){
        // TODO: newText must be a string
        this.setValue(newValue, ObservableNames.VALUE);
    },
    getProgress: function(){
        // TODO: this must return the value and not the reference
        return this.getValue(ObservableNames.VALUE);
    },
});

// Text Display
//  abbr, address, b, blockquote, br, cite, dd, dl, dt, del, dfn, em
//  figcaption, h1-6, i, img, ins, mark, meter*, output, pre, q
//  rp, rt, ruby, s, small, strong, sub, summary, sup, time, u, wbr

// Content Display
// picture, video, audio, meter, source, svg, track

// Layout
// article, aside, details, figure, footer, head, header, hr, main
// nav, section, span, template

// Unknown
// data

// Function
// area, map, audio, canvas, dialog*

/*
ViewContainer - div
    FormFieldSet - fieldset, legend

    FormView - form
        ObserverInputView - input, textarea, label
        StaticSelectView - select, label, option, optgroup, datalist
        ObserverSelectView - select, label, option, optgroup, datalist

    ~ ListView
        StaticOrderedListView - ol, li
        ObserverOrderedListView - ol, li
        StaticUnorderedListView - ul, li
        ObserverUnorderedListView - ul, li
        StaticOrderedTreeView - ol, li
        ObserverOrderedTreeView - ol, li
        StaticUnorderedTreeView - ul, li
        ObserverUnorderedTreeView - ul, li

    ~ TableView
        StaticTableView - caption, colgroup, col, table, tbody, td, tfoot, th, thead, tr
        ObserverTableView - caption, colgroup, col, table, tbody, td, tfoot, th, thead, tr

`TextView - p
`LinkView - a
`ProgressView - progress
`Button - button





*/
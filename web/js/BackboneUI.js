// Utility functions
function setDOMValue(view, key){
    // This function is one way; it updates the dom with the value of the observable property
    var binding = view.domAttrBindings[key];
    var value = view.getValue(key)
    var str = view.cid + " mappedAttr: " + key + " - " + view.objectProperty + " - " + binding + " - " + value;
    if (binding){
        //TODO: Smart figure out whether we are updating a property or an arrtibute
        if (binding == "checked"){
            view.$el.prop(binding, value);
            //console.log("bind prop - " + str);
        } else {
            view.$el.attr(binding, value);
            //console.log("bind attr - " + str);
        }
    } else if(key == ObservableNames.TEXT){
        view.$el.text(value);
        //console.log("text - " + str);
    } else if ((key == view.objectProperty || key == ObservableNames.OBJECT)){
        view.$el.val(value);
        //console.log("val - " + str);
    } else {
        console.log("no match - " + str);
        return false;
    }
    return true;
}

function getDOMValue(view, key){
    // This function is one way; it updates the dom with the value of the observable property
    var binding = view.domAttrBindings[key];
    var value = undefined;
    var str = view.cid + " get:mappedAttr: " + key + " - " + view.objectProperty + " - " + binding + " - " + value;
    if (binding){
        //TODO: Smart figure out whether we are updating a property or an arrtibute
        if (binding == "checked"){
            value = view.$el.prop(binding);
            //console.log("bind prop - " + str);
        } else {
            value = view.$el.attr(binding);
            //console.log("bind attr - " + str);
        }
    } else if(key == ObservableNames.TEXT){
        value = view.$el.text();
        //console.log("text - " + str);
    } else if ((key == view.objectProperty || key == ObservableNames.OBJECT)){
        value = view.$el.val();
        //console.log("val - " + str);
    } else {
        console.log("get:no match - " + str);
    }
    return value;
}


// Declare the "enums" we need
var EventList = {
    OBSERVE_CHANGE: "observedChange", // Args: observable, observableName, oldValue, newValue
    BUTTON_CLICKED: "buttonClick", //TODO: What arguments should be passed?
    OBSERVED_VALUE_CHANGE: "observePropertyChanged", // Args: observableName, oldValue, newValue
};
var ObservableNames = {
    OBJECT: "object",
    //---- HTML Attributes ----
    HREF: "attr-href",
    HIDDEN: "prop-hidden",
    INPUT_CHECKED: "input_attr-checked",
    INPUT_DISABLED: "input_attr-disabled",
    INPUT_MAX: "input_attr-max",
    INPUT_MAXLENGTH: "input_attr-maxlength",
    INPUT_MIN: "input_attr-min",
    INPUT_PATTERN: "input_attr-pattern",
    INPUT_READONLY: "input_attr-readonly",
    INPUT_REQUIRED: "input_attr-required",
    INPUT_SIZE: "input_attr-size",
    INPUT_STEP: "input_attr-step",
    INPUT_INIT_VALUE: "input_attr-value",
    INPUT_LABEL_TEXT: "input_label",
    //---- HTML ----
    TEXT: "html-innerText",
};

var TextInputViewTypes = {
    DT_DATE: "date",
    DT_LOCAL: "datetime-local",
    EMAIL: "email",
    DT_MONTH: "month",
    PASSWORD: "password",
    SEARCH: "search",
    TELEPHONE: "tel",
    TEXT: "text",
    DT_TIME: "time",
    URL: "url",
    DT_WEEK: "week",
    COLOR: "color", // This is placed with the "text" types because it uses a string internally
    TEXTAREA: "##textarea"
};
var ButtonInputViewTypes = {
    BUTTON: "button",
    RESET: "reset",
    SUBMIT: "submit",
};
var SelectionInputViewTypes = {
    RADIO: "radio",
    SELECT: "##select" // The ## is a magic value to allow easy detection of non "input" tag inputs
};
var NumberInputViewTypes = {
    NUMBER: "number",
    RANGE: "range",
};
var InputViewTypes = {
    //FILE: "file", // This is commented out because it has a class dedicated to it so no enum value is needed
    //: "hidden",
    //IMAGE: "image", // This is commented out because it's function doesn't make much sense in a ui toolkit (And there are better ways to implement it's function)
    //CHECKBOX: "checkbox", // This is commented out because it has a class dedicated to it so no enum value is needed
    COLOR: TextInputViewTypes.COLOR,
    DT_DATE: TextInputViewTypes.DT_DATE,
    DT_LOCAL: TextInputViewTypes.DT_LOCAL,
    EMAIL: TextInputViewTypes.EMAIL,
    DT_MONTH: TextInputViewTypes.DT_MONTH,
    PASSWORD: TextInputViewTypes.PASSWORD,
    SEARCH: TextInputViewTypes.SEARCH,
    TELEPHONE: TextInputViewTypes.TELEPHONE,
    TEXT: TextInputViewTypes.TEXT,
    DT_TIME: TextInputViewTypes.DT_TIME,
    URL: TextInputViewTypes.URL,
    DT_WEEK: TextInputViewTypes.DT_WEEK,
    TEXTAREA: TextInputViewTypes.TEXTAREA,
    BUTTON: ButtonInputViewTypes.BUTTON,
    CHECKBOX: ButtonInputViewTypes.CHECKBOX,
    RESET: ButtonInputViewTypes.RESET,
    SUBMIT: ButtonInputViewTypes.SUBMIT,
    RADIO: SelectionInputViewTypes.RADIO,
    SELECT: SelectionInputViewTypes.SELECT,
    NUMBER: NumberInputViewTypes.NUMBER,
    RANGE: NumberInputViewTypes.RANGE,
};

 // "Interfaces"
var IButton = {
    handleClick: function(){
        //TODO: What arguments should be passed?
        if(this.clickHandler){
            this.clickHandler();
        } else {
            console.log("Warning: no click handler is registered");
        }
        this.trigger(EventList.BUTTON_CLICKED);
    },
};
var IDataProvider = {};

var BaseModelView = Object.create(null);
BaseModelView.model = null;
BaseModelView.setModel = function(newModel){
    if(this.model){
        this.model.stopListening()
    }
    this.model = newModel;
    this.trigger("modelChanged", newModel);
};
BaseModelView.getModel = function(){
    return this.model || null;
};

// All backbone objects are observers so we only need to create a generic observable
var Observable = function(value){
    this.object = value; // Don't use setValue so as to avoid triggering a change event on init

    this.setValue = function(newValue, silent){
        var oldValue = this.getValue();
        this.object = newValue;
        if (silent != true){
            this.trigger(EventList.OBSERVE_CHANGE, this, undefined, oldValue, newValue);
        }
    };

    this.getValue = function(){
        return this.object;
    };
    _.extend(this, Backbone.Events);
};

// This is the base class for all BackboneUI compatible views
var ObservableView = Backbone.View.extend({
    //_observableAttrib_: [ObservableNames.OBJECT],
    objectProperty: ObservableNames.OBJECT,
    domAttrBindings: {[ObservableNames.HIDDEN]: "hidden"},
    events: function(){
        var vals = Object.values(this.domAttrBindings);
        console.log("Registering " + vals.length + " events for " + this.domAttrBindings);
        evts = {};

        vals.forEach(function(item, index){
            evts[item] = "onMappedAttrEvent"; // Register all events to use this function
        });
        return evts;
    },
    initialize: function(properties){
        this.observables = {};

        if(!this.domAttrBindings[this.objectProperty] && this.objectProperty != ObservableNames.OBJECT && this.objectProperty != ObservableNames.TEXT){
            console.log("Warning: View " + this.cid + ":" + this.tagName + " has not provided a mapping for it's objectProperty " + this.objectProperty + "; Things are likely going to not work");
            this.setValue(getDOMValue(this, this.objectProperty), this.objectProperty);
        }

        if(!properties){
            properties = {};
        }

        // Here we initialise the observables for the passed in values
        var self = this;
        Object.keys(properties).forEach(function(item, index){
            if (properties[item]){
                // We default to creating observable objects
                self.setValue(properties[item], item);
            }
        });

        // Then we synchronize any bound dom attributes with their observable's value
        Object.keys(this.domAttrBindings).forEach(function(item){
            // We check to make sure that we haven't already set the value (This is to avoid causing excess/duplicate events to fire)
            if (!properties[item]){
                var value = getDOMValue(self, item);
                var observ = self.getObservable(item);

                // The duplicated reference here is used later to detect if the initial value _was_ null
                var obse = observ;
                if(observ == null){
                    // Then we create a new one
                    obse = new Observable(value);
                }
                // We set the value of the observable
                // The "true" mutes the event that would be fired since we are insuring a correct initial state and don't want the event
                obse.setValue(value, item, true);

                if(observ == null){
                    // We don't mute the event here so that anything that depends on this observable will know that it's reference has changed
                    self.setRawValue(obse, item);
                }
            }
        });
    },
    onMappedAttrEvent: function(evt){
        console.log("Mapped event: " + evt);
    },
    updateMappedAttr: function(key){
        return setDOMValue(this, key);
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
        if(!valueName){
            valueName = ObservableNames.OBJECT;
        }

        if(newValue instanceof Observable/* || !this._observableAttrib_.includes(valueName)*/){
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
                //observ.trigger(EventList.OBSERVE_CHANGE, observ, valueName, undefined, newValue);
            }
        }
    },
    setRawValue: function(newValue, valueName, silent){
        if(!valueName){
            valueName = ObservableNames.OBJECT;
        }

        var oldObserve = this.getObservable(valueName);
        if (oldObserve != null && oldObserve != newValue && newValue instanceof Observable){
            this.stopListening(oldObserve);
            oldObserve = null;
        }

        if(newValue instanceof Observable && oldObserve == null){
            //console.log("short if");
            this.listenTo(newValue, EventList.OBSERVE_CHANGE, function(observable, observeName, oldValue, newVal){
                this.onObservedChange(valueName, oldValue, newVal); // Call the class event handler for when an observable is changed to a new one
            });
        }

        var oldValue = this.observables[valueName];
        this.observables[valueName] = newValue;
        if (this.objectProperty == valueName){
            this.observables[ObservableNames.OBJECT] = newValue;
        }

        // This must happen after the above block
        if (newValue instanceof Observable && silent != true){
            // Now we trigger the event that would normally fire if the observable had already existed
            newValue.trigger(EventList.OBSERVE_CHANGE, newValue, valueName, oldValue, newValue);
        }
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
    onObservedChange: function(observedProperty, oldValue, newValue){
        this.updateMappedAttr(observedProperty); // Update the bound element attributes and properties
        this.trigger(EventList.OBSERVED_VALUE_CHANGE, observedProperty, oldValue, newValue); // Then notify any other listeners that one of our values has changed
        this.render();  // Finally render the view after all possibility for data change is done
    },
    // --------------------
    hide: function(){
        this.setVisible(false);
    },
    show: function(){
        this.setVisible(true);
    },
    setVisible: function(isVisible){
        this.setValue(!isVisible, ObservableNames.HIDDEN);
    },
});

var ViewContainer = ObservableView.extend({
    views: null,
    tagName: "div",
    initialize: function(element, attributes){
        TextView.prototype.initialize.apply(this, [attributes]);
        this.views = [];
        if(element){
            this.setElement(element);
        }
    },
    render: function(){
        if (this.views){
            var self = this;
            console.log("ViewContainer.render");
            this.$el.empty(); // TODO: I don't like the erase and reset model, fix it
            this.views.forEach(function(item){
                item.render();
                self.$el.append(item.$el);
            })
        }
    },
    addView: function(view){
        this.views.push(view);
    },

    //TODO: Add a way to remove views and possibly to get specific views by name
});

var TextView = ObservableView.extend({
    tagName: "p",
    objectProperty: ObservableNames.TEXT,
    //_observableAttrib_: [...ObservableView.prototype._observableAttrib_, ObservableNames.TEXT],
    render: function(){
        //this.$el.text(this.getText());
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
    //_observableAttrib_: [...TextView.prototype._observableAttrib_, ObservableNames.HREF],
    domAttrBindings: {[ObservableNames.HREF]: "href"},
    render: function(){
        //this.$el.attr("href", this.getHref());
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
    events: {
        "click" : "handleClick",
    },
    initialize: function(onClick, attributes){
        TextView.prototype.initialize.apply(this, [attributes]);
        this.$el.attr("class", "pure-button");
        //TODO: Implement functionality to support all button classes at https://purecss.io/buttons/
        this.clickHandler = onClick;
    },
});
_.extend(ButtonView.prototype, IButton); // <- This is not true inheritance but works like it
var ProgressView = ObservableView.extend({ //TODO: This should also support the "meter" tag
    tagName: "progress",
    //----------------------------------------
    setProgress: function(newValue){
        // TODO: newText must be a string
        this.setValue(newValue, ObservableNames.OBJECT);
    },
    getProgress: function(){
        // TODO: this must return the value and not the reference
        return this.getValue(ObservableNames.OBJECT);
    },
    getMaxValue: function(){
        return this.getValue(ObservableNames.INPUT_MAX);
    },
    setMaxValue: function(newValue){
        return this.setValue(newValue, ObservableNames.INPUT_MAX);
    },
});

var BaseInputView = TextView.extend({
    tagName: "input",
    objectProperty: ObservableNames.INPUT_INIT_VALUE,
    objectProperty: ObservableNames.INPUT_INIT_VALUE,
    inputType: "",
    events: {
        "change": "_domOnChange_",
        "input": "_domOnModify_", // <- This is disabled by default to avoid spaming events
        "click": "handleClick",
    },
    _domOnChange_: function(evt){
        this.setValue(evt.target.value);
        //console.log(this.type + " - " + this.name + " was changed to " + evt.target.value);
    },
    _domOnModify_: function(evt){
        // We call onChange by default
        // NOTE: This will cause events to double fire for some views, like checkboxes
        // to fix this just override onModify with an empty function in the affected views
        this._domOnChange_(evt);
    },
    initialize: function(type, name, attributes){
        TextView.prototype.initialize.apply(this, [attributes]);
        this.type = type;
        this.name = name;

        // This attr's are intended to be imutable after they are set
        this.$el.attr("type", this.type);
        this.$el.attr("name", this.name);

        _.extend(this, IButton);
    },
    getName: function(){
        return this.name;
    },
    getLabelText: function(){
        return this.getValue(ObservableNames.INPUT_LABEL_TEXT);
    },
    setLabelText: function(newValue){
        return this.setValue(newValue, ObservableNames.INPUT_LABEL_TEXT);
    },
    //TODO: Getters and setters for all the INPUT_* observable names
});
var TextInputView = BaseInputView.extend({ //TODO: Implement datalist support
    initialize: function(type, name, attributes){
        //TODO: Add checks to ensure that only valid "text" imput types can be passed
        BaseInputView.prototype.initialize.apply(this, [type, name, attributes]);
    },
});
var ButtonInputView = BaseInputView.extend({
    objectProperty: ObservableNames.TEXT,
    initialize: function(type, name, onClick, attributes){
        //TODO: Add checks to ensure that only valid "button" imput types can be passed
        BaseInputView.prototype.initialize.apply(this, [type, name, attributes]);
        this.clickHandler = onClick;
    },
});
_.extend(ButtonInputView.prototype, IButton); // <- This is not true inheritance but works like it
var CheckBoxInputView = BaseInputView.extend({
    objectProperty: ObservableNames.INPUT_CHECKED,
    domAttrBindings: _.extend(BaseInputView.prototype.domAttrBindings, {[ObservableNames.INPUT_CHECKED]: "checked"}),
    initialize: function(name, attributes){
        //TODO: Add checks to ensure that only valid "text" imput types can be passed
        BaseInputView.prototype.initialize.apply(this, ["checkbox", name, attributes]);
    },
    _domOnChange_: function(evt){
        //TODO: I think calling setTicked here causes the code to loop back around and set the tick box with the same value it has
        // this occurs in updateMappedAttr
        this.setTicked(evt.target.checked);
        console.log(this.type + " - " + this.name + " was changed to " + evt.target.checked);
    },
    _domOnModify_: function(evt){},
    isTicked: function(){
        return this.getValue();
    },
    setTicked: function(isTicked){
        return this.setValue(isTicked);
    },
});
var SelectionInputView = BaseInputView.extend({
    tagName: "select",
    initialize: function(collection, optionNameKey, includeNA, attributes){
        BaseInputView.prototype.initialize.apply(this, [attributes]);
        //this.initUnselected = getOrDefault(args, "initUnselected", false);
        //this.noSelection = includeNA;// {text: "N/A", value: -1}
        this.collection = collection;
        if (typeof optionNameKey === "function"){
            this.nameFormatter = optionNameKey;
            this.nameKey = "name"; // TOOD: This is a hard coded value that shouldn't be
        } else {
            // For now we just assume the variable is a string
            this.nameFormatter = function(model){
                return model.get(optionNameKey);
            }
            this.nameKey = optionNameKey;
        }
        //this.options = [{text: "No Options", value: 0, selected: true, defaultSelected: true}];

        //TODO: this.listenTo(newModel, "add", this.render)
        //TODO: this.listenTo(newModel, "remove", this.render)
        this.listenTo(collection, "update", this.refreshOptions)
        this.listenTo(collection, "reset", this.refreshOptions)
        this.listenTo(collection, "sort", this.refreshOptions)
        this.listenTo(collection, "change:" + this.nameKey, this.refreshOptions) //TODO: Inefficient
        //TODO: this.listenTo(newModel, "request", this.render)
        //TODO: this.listenTo(newModel, "sync", this.render)
        this.refreshOptions();
    },
    refreshOptions: function(){
        console.log("SelectView.refreshOptions")
        var lastState =  this.$el.prop("disabled");
        this.$el.prop("disabled", true);

        this.$el[0].options.length=0

        var value = -1; // TODO: this is a placeholder
        if(this.noSelection){
            this.$el[0].options.add(new Option(this.noSelection.text, this.noSelection.value, true, (this.noSelection.value == value)));
        }

        var self = this;
        this._getOptions().forEach(function(item, index){
            self.$el[0].options.add(new Option(item.text, item.value, item.defaultSelected, item.selected));
        });

        this.$el.prop("disabled", lastState);

        this.$el.change();
    },
    _getOptions: function(){
        var value = -1; //TODO: Placeholder
        var options = [];
        if (this.collection){
            var self = this;
            this.collection.where().forEach(function(ite, ind){
                var text = self.nameFormatter(ite);
                options.push({text: text, value: ite.cid, defaultSelected: false, selected: (value == ite.id)});
            });
        }
        return options;
    },
    _domOnChange_: function(data){
        //TODO: Support multiple selection
        var options = data.target.selectedOptions;

        if (options.length > 0){
            var val = options[0].value;

            // TODO: Is it better to set value to the model or the model's id?
            // For now we use the model id (It's easiest to change later)
            if(this.collection){
                var model = this.collection.get(val);
                if(model && this.getValue() != val){
                    // We check that the new value is not the old value to avoid double firing the change event
                    this.setValue(model.cid);
                }
            }
        }
    },
});
var NumberInputView = BaseInputView.extend({
    objectProperty: ObservableNames.INPUT_INIT_VALUE,
    domAttrBindings: _.extend(BaseInputView.prototype.domAttrBindings, {[ObservableNames.INPUT_MAX]: "max"}),
    initialize: function(type, name, attributes){
        //TODO: Add checks to ensure that only valid "text" imput types can be passed
        BaseInputView.prototype.initialize.apply(this, [type, name, attributes]);
    },
    getMinValue: function(){
        return this.getValue(ObservableNames.INPUT_MIN);
    },
    getMaxValue: function(){
        return this.getValue(ObservableNames.INPUT_MAX);
    },
    getStepValue: function(){
        return this.getValue(ObservableNames.INPUT_STEP);
    },
    setMinValue: function(newValue){
        return this.setValue(newValue, ObservableNames.INPUT_MIN);
    },
    setMaxValue: function(newValue){
        return this.setValue(newValue, ObservableNames.INPUT_MAX);
    },
    setStepValue: function(newValue){
        return this.setValue(newValue, ObservableNames.INPUT_STEP);
    },
});
//var FileInputView;

// This extends observable view so that properties like visibility, color, etc. can be observed easily
// This view also functions as a good example of the most minimal implementation of a view widget
var HorizontalRuleView = ObservableView.extend({
    tagName: "hr",
});
var LineBreakView = ObservableView.extend({
    tagName: "br",
});

// Text Display
//  abbr, address, b, blockquote, cite, dd, dl, dt, del, dfn, em
//  figcaption, h1-6, i, img, ins, mark, output, pre, q
//  rp, rt, ruby, s, small, strong, sub, summary, sup, time, u, wbr

// Content Display
// picture, video, audio, meter, source, svg, track

// Layout
// article, aside, details, figure, footer, head, header, main
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
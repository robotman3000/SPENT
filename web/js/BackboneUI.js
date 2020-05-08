// All backbone objects are observers so we only need to create a generic observable
var EventList = {
    OBSERVE_CHANGE: "observedChange", // Args: observable, oldValue, newValue
    BUTTON_CLICKED: "buttonClick", //TODO: What arguments should be passed?
};

var ObservableObject = function(value){
    this.object = value;
    this.setValue = function(newValue){
        var oldValue = this.object;
        this.object = newValue;
        this.trigger(EventList.OBSERVE_CHANGE, oldValue, newValue);
    };

    this.getValue = function(newValue){
        return this.object;
    };
    _.extend(this, Backbone.Events);
};


var ViewContainer = Backbone.View.extend({
    views: null,
    initialize: function(element){
        this.views = [];
        this.setElement(element);
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

var TextView = Backbone.View.extend({
    tagName: "p",
    initialize: function(text){
        this.text = text;
    },
    render: function(){
        this.$el.text(this.text);
    },
    //----------------------------------------
    setText: function(newText){
        // TODO: newText must be a string
        this.text = newText;
    },
    getText: function(){
        // TODO: this must return the value and not the reference
        return this.text;
    },
});
var ObserverTextView = TextView.extend({
    initialize: function(observable){
        // The observable cannot be changed after it is set, but we don't
        // keep the reference because we never use it again

        this.setText(observable.getValue());

        // TODO: is it more memory efficient to declare the function here or in the object prototype?
        var self = this;
        var onObserveChange = function(oldValue, newValue){
            self.setText(newValue);
            self.render();
        };
        this.listenTo(observable, EventList.OBSERVE_CHANGE, onObserveChange);
    }
});

var ButtonView = TextView.extend({
    tagName: "button",
    initialize: function(onClick, buttonText){
        TextView.prototype.initialize.apply(this, [buttonText]);
        this.clickHandler = onClick;
    },
    events: {
        "click" : "onClick",
    },
    onClick: function(){
        //TODO: What arguments should be passed?
        this.clickHandler()
        this.trigger(EventList.BUTTON_CLICKED)
    },
});
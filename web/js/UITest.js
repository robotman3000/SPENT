function main(){
    tests = [getLinkTestView, getButtonTestView, getInputTest1View, getInputTest2View, getInputTest3View, getInputTest4View, getVisibilityToggleTestView, getSelectViewTest];
    var theContainer = new ViewContainer($("#container"));

    tests.forEach(function(item, index){
        try {
            theContainer.addView(item());
        } catch (error) {
            var strin = "Failed to initialize view test; Index: " + index;
            console.error(error);
            console.error(strin);
            theContainer.addView(new TextView({[ObservableNames.TEXT]: strin}));
            // expected output: ReferenceError: nonExistentFunction is not defined
            // Note - error messages will vary depending on browser
        }

        theContainer.addView(new HorizontalRuleView());
    });

    theContainer.render();
}

function getLinkTestView(){
    var theLinkTest = new LinkView();
    theLinkTest.setText("Ask the duck.");
    theLinkTest.setHref("https://duckduckgo.com");
    return theLinkTest;
}

function getButtonTestView(){
    var theString = new Observable("Hello World");

    var textView = new TextView({[ObservableNames.TEXT]: theString});

    var theButton = new ButtonView(function(){
        theString.setValue("World Hello");
    });
    theButton.setText("olleH");

    var theOtherButton = new ButtonView(function(){
        theString.setValue("Hello World!!!");
    });
    theOtherButton.setText("Hello");

    var theLastButton = new ButtonView(function(){
        theString.setValue("Hello World");
    }, {[ObservableNames.TEXT]: "Reset"});

    var con1 = new ViewContainer();
    con1.addView(textView);
    con1.addView(theButton);
    con1.addView(theOtherButton);
    con1.addView(theLastButton);

    return con1;
}

function getInputTest1View(){
    var theProgress = new ProgressView({[ObservableNames.INPUT_MAX]: 100});
    theProgress.setProgress(50);
    var theProgressText = new TextView({[ObservableNames.TEXT]: theProgress.getObservable(ObservableNames.OBJECT)});
    var theProgressButton = new ButtonView(function(){
        theProgress.setProgress(Math.floor(Math.random()*100));
    });
    theProgressButton.setText("Change Progress");
    var theInputTest = new NumberInputView(NumberInputViewTypes.RANGE, "testNumber");
    theInputTest.setValue(theProgress.getObservable(ObservableNames.OBJECT));

    var theInputTest2 = new NumberInputView(NumberInputViewTypes.NUMBER, "testNumber2");
    theInputTest2.setValue(theProgress.getObservable(ObservableNames.OBJECT));

    var maxObserv = theProgress.getObservable(ObservableNames.INPUT_MAX);
    theInputTest.setMaxValue(maxObserv);
    theInputTest2.setMaxValue(maxObserv);

    var maxControl = new NumberInputView(NumberInputViewTypes.NUMBER, "maxValControl");
    maxControl.setValue(maxObserv);

    var con2 = new ViewContainer();
    con2.addView(theProgress);
    con2.addView(theProgressButton);
    con2.addView(theProgressText);
    con2.addView(theInputTest);
    con2.addView(theInputTest2);
    con2.addView(maxControl);

    return con2;
}

function getInputTest2View(){
    var theMultiplexedOne = new Observable();

    var textView = new TextView();
    textView.setText(theMultiplexedOne); // Note how we passed an observable rather than a string
    textView.setText("Initial Text"); // and then used the same function to set the actual text string of the observable

    var inputs = [TextInputViewTypes.DT_DATE, TextInputViewTypes.DT_LOCAL, TextInputViewTypes.EMAIL, TextInputViewTypes.DT_MONTH, TextInputViewTypes.PASSWORD, TextInputViewTypes.SEARCH, TextInputViewTypes.TELEPHONE, TextInputViewTypes.TEXT, TextInputViewTypes.DT_TIME, TextInputViewTypes.URL, TextInputViewTypes.DT_WEEK];

    var container = new ViewContainer();
    container.addView(textView);
    inputs.forEach(function(item, index){
        var view = new TextInputView(item, "text" + index);
        view.setValue(theMultiplexedOne);
        container.addView(new LineBreakView());
        container.addView(new TextView({[ObservableNames.TEXT]: item}));
        container.addView(view);
        container.addView(new LineBreakView());
        console.log(item);
    });
    return container;
}

function getInputTest3View(){
    var theMultiplexedOne = new Observable(0);

    var textView = new TextView();
    textView.setText(theMultiplexedOne); // Note how we passed an observable rather than a string

    var textView2 = new TextView();
    textView2.setText("Test Initial Text")

    var inputs = [ButtonInputViewTypes.BUTTON, ButtonInputViewTypes.RESET, ButtonInputViewTypes.SUBMIT];

    var counter = 0;
    var testOnClick = function(){
        counter = counter + 1;
        theMultiplexedOne.setValue(counter);
        textView2.setText("A " + this.type + " was clicked");
    }

    var container = new ViewContainer();
    container.addView(textView);
    container.addView(textView2);
    inputs.forEach(function(item, index){
        var view = new ButtonInputView(item, "button" + index, testOnClick);
        view.setValue(theMultiplexedOne);
        container.addView(new LineBreakView());
        container.addView(new TextView({[ObservableNames.TEXT]: item}));
        container.addView(view);
        container.addView(new LineBreakView());
        console.log(item);
    });
    return container;
}

function getInputTest4View(){
    var tickBoxNames = ["Cat", "Dog", "Fish", "Snake", "Duck"];
    var textBox = new TextView();
    textBox.setText("Starting Text");
    var container = new ViewContainer();
    container.addView(textBox);

    var onValueChange = function(name, oldValue, newValue){
        textBox.setText("You changed " + this.getName() + " from " + oldValue + " to " + newValue);
    };

    tickBoxNames.forEach(function(item, index){
        var tickBox = new CheckBoxInputView("tick" + item);
        tickBox.setLabelText(item);
        var boo = Math.random() >= 0.5;
        //console.log("bool: " + boo);
        tickBox.setTicked(boo);
        container.addView(tickBox);
        tickBox.on(EventList.OBSERVED_VALUE_CHANGE, onValueChange);
        console.log("Initial tick value: " + tickBox.$el.prop("checked") + "; Observable value: " + tickBox.getValue());
    });

    return container;
}

function getVisibilityToggleTestView(){
    var textView = new TextView({[ObservableNames.TEXT]: "Hello World"});

    // Assert that the view is visible by default
    textView.setVisible(true);

    // Note how we link the text property of our TextView to the value of the "hidden" obervable in the other TextView
    // Technical Note: This actually makes the "text" observable be a reference to the "hidden" observable
    var visibleStateView = new TextView({[ObservableNames.TEXT]: textView.getObservable(ObservableNames.HIDDEN)});

    var theButton = new ButtonView(function(){
        textView.show();
    });
    theButton.setText("Visible");

    var theOtherButton = new ButtonView(function(){
        textView.hide();
    });
    theOtherButton.setText("Hidden");

    var con1 = new ViewContainer();
    con1.addView(theButton);
    con1.addView(theOtherButton);
    con1.addView(textView);
    con1.addView(visibleStateView);

    return con1;
}

function getSelectViewTest(){
    var textView = new TextView({[ObservableNames.TEXT]: "Initial Select Text"});

    var Surfboard = Backbone.Model.extend({
        defaults: {
            manufacturer: '',
            model: '',
            stock: 0
        }
    });

    var SurfboardsCollection = Backbone.Collection.extend({
        model: Surfboard
    });

    var board1 = new Surfboard({
        manufacturer: 'Channel Islands',
        model: 'Whip',
        stock: 12
    });
    var board2 = new Surfboard({
        manufacturer: 'Surf Co',
        model: 'Surf 3000',
        stock: 1
    });
    var board3 = new Surfboard({
        manufacturer: 'Artistic Licence',
        model: 'Fling',
        stock: 26
    });
    var surfboards = new SurfboardsCollection;
    surfboards.add(board1);
    surfboards.add(board2);
    surfboards.add(board3);

    var viewContainer = new ViewContainer();

    var selectView = new SelectionInputView(surfboards, "model", false);
    console.log("Initial select value: " + selectView.$el.val() + "; Observable value: " + selectView.getValue());
    textView.setText(selectView.getObservable(ObservableNames.OBJECT));
    //selectView.render();
    viewContainer.addView(selectView);
    viewContainer.addView(textView);
    return viewContainer;
}
function main(){
    tests = [getLinkTestView, getButtonTestView, getInputTest1View, getInputTest2View, getInputTest3View, getInputTest4View];
    var theContainer = new ViewContainer($("#container"));

    tests.forEach(function(item){
        theContainer.addView(item());
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
        tickBox.setTicked(Math.random() >= 0.5);
        container.addView(tickBox);
        tickBox.on(EventList.OBSERVED_VALUE_CHANGE, onValueChange);
    });

    return container;
}
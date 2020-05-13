function main(){
    tests = [getLinkTestView, getButtonTestView, getInputTest1View, getInputTest2View];
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
    var theProgress = new ProgressView(100);
    theProgress.setProgress(0.5);
    var theProgressText = new TextView({[ObservableNames.TEXT]: theProgress.getObservable(ObservableNames.OBJECT)});
    var theProgressButton = new ButtonView(function(){
        theProgress.setProgress(Math.floor(Math.random()*100));
    });
    theProgressButton.setText("Change Progress");
    var theInputTest = new InputView(InputViewTypes.RANGE, "testNumber");
    theInputTest.setValue(theProgress.getObservable(ObservableNames.OBJECT));

    var theInputTest2 = new InputView(InputViewTypes.NUMBER, "testNumber");
    theInputTest2.setValue(theProgress.getObservable(ObservableNames.OBJECT));

    var con2 = new ViewContainer();
    con2.addView(theProgress);
    con2.addView(theProgressButton);
    con2.addView(theProgressText);
    con2.addView(theInputTest);
    con2.addView(theInputTest2);

    return con2;
}

function getInputTest2View(){
    var theMultiplexedOne = new Observable("Many -> single -> many relationships (TODO)");

    var textView = new TextView();
    textView.setText(theMultiplexedOne); // Note how we passed an observable rather than a string

    var inputs = [InputViewTypes.BUTTON, InputViewTypes.CHECKBOX, InputViewTypes.COLOR, InputViewTypes.DT_DATE, InputViewTypes.DT_LOCAL, InputViewTypes.EMAIL, /*InputViewTypes.FILE,*/ InputViewTypes.IMAGE, InputViewTypes.DT_MONTH, InputViewTypes.NUMBER, InputViewTypes.PASSWORD, InputViewTypes.RADIO, InputViewTypes.RANGE, InputViewTypes.RESET, InputViewTypes.SEARCH, InputViewTypes.SUBMIT, InputViewTypes.TELEPHONE, InputViewTypes.TEXT, InputViewTypes.DT_TIME, InputViewTypes.URL, InputViewTypes.DT_WEEK];

    var container = new ViewContainer();
    container.addView(textView);
    inputs.forEach(function(item, index){
        var view = new InputView(item, index);
        view.setValue(theMultiplexedOne);
        container.addView(new LineBreakView());
        container.addView(new TextView({[ObservableNames.TEXT]: item}));
        container.addView(view);
        container.addView(new LineBreakView());
        console.log(item);
    });
    return container;
}
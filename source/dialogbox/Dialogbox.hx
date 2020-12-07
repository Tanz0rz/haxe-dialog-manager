package dialogbox;

import haxe.Timer;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.text.FlxTypeText;
import flixel.input.keyboard.FlxKey;
import hx.concurrent.executor.Executor;

class Dialogbox extends FlxBasic {
    // constants
    static inline final CharactersPerTextBox = 100;
    static inline final NextPageDelayMs = 4000;
    static inline final NextPageInputDelayMs = 500;

    public var typeText:FlxTypeText;
    var progressionKey:FlxKey;
    var onTypingBegin:() -> Void;
    var onTypingEnd:() -> Void;

    var pages:Array<String>;
    var currentPage:Int = 0;
    var typing:Bool;
    var canManuallyTriggerNextPage:Bool;

    // Keep references to the timers to reset them whenever a new page of text starts
    var autoProgressTimer:Timer;
    var manuallyProgressTimer:Timer;

    public function new( _typeText:FlxTypeText, ?_progressionKey:FlxKey = null, ?_onTypingBegin:() -> Void = null, ?_onTypingEnd:() -> Void = null) {
        super();
        progressionKey = _progressionKey;
        typeText = _typeText;
        onTypingBegin = _onTypingBegin;
        onTypingEnd = _onTypingEnd;
    }

    public function loadDialog(textList:Array<String>) {
        pages = parseTextIntoPages(textList);
        typeText.resetText(pages[0]);
        startTyping();
    }
    
    public function startTyping():Void {
        typing = true;
        typeText.showCursor = false;
        typeText.start(.05, true, false, [], () -> {
            typing = false;
            typeText.showCursor = true;

            if (onTypingEnd != null){
                onTypingEnd();
            }

            // After NextPageDelayMs, the next page of text will be loaded
            autoProgressTimer = Timer.delay(() -> {
                continueToNextPage();
            }, NextPageDelayMs);

            // After NextPageInputDelayMs, the user can press a button to continue to the next page instead of waiting
            manuallyProgressTimer = Timer.delay(() -> {
                canManuallyTriggerNextPage = true;
            }, NextPageInputDelayMs);
        });

        if (onTypingBegin != null){
            onTypingBegin();
        }
    }

    private function parseTextIntoPages(_textList:Array<String>):Array<String> {
        var pageArray = new Array<String>();
        var currentPageBuffer:StringBuf;

        for(text in _textList){
            currentPageBuffer = new StringBuf();
            for (i in 0...text.length) {
                if (i % CharactersPerTextBox == 0 && i != 0){
                    pageArray.push(currentPageBuffer.toString());
                    currentPageBuffer = new StringBuf();
                }
                currentPageBuffer.add(text.charAt(i));

                if (i == text.length-1){
                    pageArray.push(currentPageBuffer.toString());
                }
            }
        }

        return pageArray;
    }

    public function continueToNextPage():Void {
        canManuallyTriggerNextPage = false;
        autoProgressTimer.stop();
        manuallyProgressTimer.stop();

        currentPage++;
        if (currentPage >= pages.length){
            completeDialog();
        } else {
            typeText.resetText(pages[currentPage]);
            startTyping();
        }
    }

    public function completeDialog() {
        // Due to a bug with FlxTypeText, resetting the text to a single space is the cleanest way to make it invisible
        typeText.resetText(" ");
        typeText.start(.05, true);
        typeText.showCursor = false;
    }

    public function isTyping():Bool {
		return typing;
    }
    
    public function isDone():Bool {
        // Text is set to a space when it is completely done with the current dialog
        return typeText.text == " ";
    }

	override public function update(delta:Float):Void {
        super.update(delta);
        
        if(progressionKey != null){
            if (typing && FlxG.keys.anyJustPressed([progressionKey])){
                typeText.delay = 0.025;
            }
    
            if (canManuallyTriggerNextPage && FlxG.keys.anyJustPressed([progressionKey])) {
                continueToNextPage();
            }
        }
    }

    override public function destroy(){
        super.destroy();
        if (onTypingEnd != null){
            onTypingEnd();
        }
    }
}
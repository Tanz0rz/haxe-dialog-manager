package dialogbox;

import flixel.FlxBasic;
import haxe.Timer;
import flixel.FlxG;
import flixel.addons.text.FlxTypeText;
import dialogbox.Dialogs.DialogId;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import flixel.FlxState;


class DialogManager extends FlxBasic {

    static inline final FontSize = 10;
    
    var currentDialogIndex:Int = -1;
    var currentDialogId:DialogId = NoId;

    // constants
    static inline final CharactersPerTextBox = 100;
    static inline final NextPageDelayMs = 4000;
    static inline final NextPageInputDelayMs = 500;

    var progressionKey:FlxKey;
    public var typeText:FlxTypeText;

    var pages:Array<String>;
    var currentPage:Int = 0;
    var typing:Bool;
    var canManuallyTriggerNextPage:Bool;

    // Optional callbacks
    var onTypingBegin:() -> Void;
    var onTypingEnd:() -> Void;
    var onTypingSpeedUp:() -> Void;

    // Keep references to the timers to reset them whenever a new page of text starts
    var autoProgressTimer:Timer;
    var manuallyProgressTimer:Timer;

    public function new(_parentState:FlxState, _camera:FlxCamera, ?_progressionKey:FlxKey = null, ?_onTypingBegin:() -> Void = null, ?_onTypingEnd:() -> Void = null, ?_onTypingSpeedUp:() -> Void = null) {
        super();
        
        progressionKey = _progressionKey;
        onTypingBegin = _onTypingBegin;
        onTypingEnd = _onTypingEnd;
        onTypingSpeedUp = _onTypingSpeedUp;

        // Position the text to be roughly centered toward the top of the screen
        typeText = new FlxTypeText(20, 30, FlxG.width-20, "", FontSize);
        typeText.setFormat(AssetPaths.joystix_monospace__ttf);
		typeText.scrollFactor.set(0, 0);
        typeText.cameras = [_camera];
        _parentState.add(typeText);
    }

    public function loadDialog(id:DialogId){
        if (Dialogs.DialogMap[id] == null) {
            trace("Key not found for dialog");
            return;
        }
        pages = parseTextIntoPages(Dialogs.DialogMap[id].copy());
        typeText.resetText(pages[0]);
        startTyping();
        currentDialogId = id;
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

	override public function update(delta:Float):Void {
        super.update(delta);
        
        if(progressionKey != null){
            if (typing && FlxG.keys.anyJustPressed([progressionKey])){
                typeText.delay = 0.025;
                if (onTypingSpeedUp != null){
                    onTypingSpeedUp();
                }
            }
    
            if (canManuallyTriggerNextPage && FlxG.keys.anyJustPressed([progressionKey])) {
                continueToNextPage();
            }
        }
    }

	public function getCurrentDialogIndex():Int {
        return currentDialogIndex;
	}

	public function getCurrentDialogId():DialogId {
        return currentDialogId;
	}

    public function isTyping():Bool {
		return typing;
    }
    
    public function isDone():Bool {
        // Text is set to a space when it is completely done with the current dialog
        return typeText.text == " ";
    }
}
package dialogmanager;

import flixel.FlxBasic;
import haxe.Timer;
import flixel.FlxG;
import flixel.addons.text.FlxTypeText;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import flixel.FlxState;


class DialogManager extends FlxBasic {

    final fontSize = 10;
    
    var currentDialogIndex:Int = -1;
    var currentDialogId:String = "";

    // constants
    static inline final CharactersPerTextBox = 100;
    static inline final NextPageDelayMs = 4000;
    static inline final NextPageInputDelayMs = 500;

    var dialogMap:Map<String, Array<String>>;
    var progressionKey:FlxKey;
    public var typeText:FlxTypeText;

    var pages:Array<String>;
    var currentPage:Int = 0;
    var typing:Bool;
    var fastTyping:Bool = false;
    var canManuallyTriggerNextPage:Bool;

    // Optional callbacks to enable custom sound solutions
    var onTypingBegin:() -> Void;
    var onTypingEnd:() -> Void;
    var onTypingSpeedUp:() -> Void;

    // Keep references to the timers to reset them whenever a new page of text starts
    // Initialize them to real timers to avoid the need to check for null
    var autoProgressTimer:Timer = new Timer(1000);
    var manuallyProgressTimer:Timer = new Timer(1000);

    public function new(_dialogMap:Map<String, Array<String>>, _parentState:FlxState, _camera:FlxCamera, ?_progressionKey:FlxKey = FlxKey.NONE, ?_onTypingBegin:() -> Void = null, ?_onTypingEnd:() -> Void = null, ?_onTypingSpeedUp:() -> Void = null, ?_fontSize:Int = null) {
        super();

        dialogMap = _dialogMap;
        progressionKey = _progressionKey;
        onTypingBegin = _onTypingBegin;
        onTypingEnd = _onTypingEnd;
        onTypingSpeedUp = _onTypingSpeedUp;
	    
	if (_fontSize != null) {
		fontSize = _fontSize;    
	}

        // Position the text to be roughly centered toward the top of the screen
        typeText = new FlxTypeText(20, 30, FlxG.width-20, "", fontSize);
        typeText.setFormat(AssetPaths.joystix_monospace__ttf);
		typeText.scrollFactor.set(0, 0);
        typeText.cameras = [_camera];
        _parentState.add(typeText);
    }

    public function loadDialog(id:String){
        if (dialogMap[id] == null) {
            trace("id (" + id + ") not found in dialog map");
            return;
        }
        pages = parseTextIntoPages(dialogMap[id].copy());
        typeText.resetText(pages[0]);
        startTyping();
        currentDialogId = id;
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
    
    public function startTyping():Void {
        typing = true;
        fastTyping = false;
        typeText.showCursor = false;        
        canManuallyTriggerNextPage = false;
        autoProgressTimer.stop();
        manuallyProgressTimer.stop();

        // Set onComplete function in-line
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
        currentPage++;
        // When there is no more text to display, transition to completed state
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
        
        fastTyping = false;
        typeText.showCursor = false;        
        canManuallyTriggerNextPage = false;
        autoProgressTimer.stop();
        manuallyProgressTimer.stop();
    }

	override public function update(delta:Float):Void {
        super.update(delta);
        
        // Update loop exclusively handles user input
        if(progressionKey != FlxKey.NONE){
            if (typing && !fastTyping && FlxG.keys.anyJustPressed([progressionKey])){
                fastTyping = true;
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

    public function getCurrentDialogId():String {
        return currentDialogId;
    }

    public function isTyping():Bool {
		return typing;
    }
    
    public function isDone():Bool {
        // Text is set to a space when it is done displaying all text pages
        return typeText.text == " ";
    }
	
    public function getCurrentDialogPage() {
        return currentPage;	
    }
}

package dialogbox;

import flixel.FlxG;
import flixel.addons.text.FlxTypeText;
import dialogbox.Dialogs.DialogId;
import flixel.FlxCamera;
import haxefmod.FmodEvents.FmodCallback;
import haxefmod.FmodEvents.FmodEvent;
import flixel.input.keyboard.FlxKey;
import flixel.FlxState;


class DialogManager {

    static inline final FontSize = 10;
    
    var currentDialogIndex:Int = -1;
    var currentDialogId:DialogId = NoId;
    var dialogBox:Dialogbox;

    var typeText:FlxTypeText;
    

    public function new(_parentState:FlxState, _camera:FlxCamera, ?_onTypingBegin:() -> Void = null, ?_onTypingEnd:() -> Void = null) {

        // Position the text to be roughly centered toward the top of the screen
        typeText = new FlxTypeText(20, 30, FlxG.width-20, "", FontSize);
        typeText.setFormat(AssetPaths.joystix_monospace__ttf);
		typeText.scrollFactor.set(0, 0);
        typeText.cameras = [_camera];
        _parentState.add(typeText);

        // Create the dialog box that will be used to hold and type out the text
        dialogBox = new Dialogbox(typeText, FlxKey.SPACE, _onTypingBegin, _onTypingEnd);
        _parentState.add(dialogBox);
    }

    public function loadDialog(id:DialogId){
        if (Dialogs.DialogMap[id] == null) {
            trace("Key not found for dialog");
            return;
        }
        dialogBox.loadDialog(Dialogs.DialogMap[id].copy());
        currentDialogId = id;
    }

	public function getCurrentDialogIndex():Int {
        return currentDialogIndex;
	}

	public function getCurrentDialogId():DialogId {
        return currentDialogId;
	}

    public function isTyping():Bool {
        return dialogBox.isTyping();
    }

    public function isDone():Bool {
        return dialogBox.isDone();
    }
}
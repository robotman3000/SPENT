abc = 0
function initLocks(object){
	object.lockable = true
	object.isLocked1 = false;
	object.lockID = 0;
	object.name = abc += 1;
}

function lockTable(object){
	// Do table locking
	object.isLocked1 = true;

	// Return the "key"
	object.lockID += 1;
	console.log("Locking " + object.name + " with key " + object.lockID)
	return object.lockID;
}
function unlockTable(object, unlockKey){
	// Do table unlocking if id matches
	if(object.lockID == unlockKey){
		console.log("Unlocking " + object.name + " with key " + unlockKey)
		object.isLocked1 = false;
	} else {
		console.log("Error: Lock " + unlockKey + " attempted to unlock " +  object.lockID + " on " + object.name)
	}
}
function isLocked(object, lockID){
	var result = object.isLocked;
	if (lockID && lockID == object.lockID){
		console.log("Obj " + object.name + " can be accessed by " + lockID);
		result = false;
	}

	console.log("Obj " + object.name + " is " + (result ? "locked with key " + object.lockID : "not locked"))
	//return false;
	return result;
}
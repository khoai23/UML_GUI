import MusicControllerWWISE
from MusicControllerWWISE import MusicController, MUSIC_EVENT_COMBAT, MUSIC_EVENT_LOBBY
import SoundGroups
import WWISE
from debug_utils import LOG_ERROR, LOG_WARNING, LOG_DEBUG

from Avatar import PlayerAvatar
import BigWorld, ResMgr

"""prototype concept test:
- inject and listen to music events from https://github.com/IzeBerg/wot-src/blob/master/sources/res/scripts/client/MusicControllerWWISE.py#L202
- use internal WWISE to build mp3 events from https://github.com/IzeBerg/wot-src/blob/master/sources/res/scripts/client/SoundGroups.py#L518
- listen to player statistic from https://github.com/IzeBerg/wot-src/blob/master/sources/res/scripts/client/Avatar.py

# arena sound event, called from SoundGroups
# redundant if injecting from play
old__onArenaStateChanged = MusicController._MusicController__onArenaStateChanged
def new__onArenaStateChanged(self, *args):
    if(self._skipArenaChanges):
        return
    # print("DEBUG: arena object:  {}".format(dir(BigWorld.player().arena)))
    print("Injected in MusicController's __onArenaStateChanged. Period: {}".format(BigWorld.player().arena.period))
    return old__onArenaStateChanged(self, *args)
MusicController._MusicController__onArenaStateChanged = new__onArenaStateChanged

old__getArenaSoundEvent = MusicController._MusicController__getArenaSoundEvent
def new__getArenaSoundEvent(self, eventId):
    print("Injected in MusicController's __getArenaSoundEvent. eventId: {}".format(eventId))
    return old__getArenaSoundEvent(self, eventId)
MusicController._MusicController__getArenaSoundEvent = new__getArenaSoundEvent

# inject and see what WW_setRTCPGlobal do
# apparently, nothing. nothing worth looking for.
old_setEventParam = MusicController.setEventParam
def new_setEventParam(self, paramName, paramValue):
    print("Injected in MusicController's setEventParam. param name/value: {} {}".format(paramName, paramValue))
    return old_setEventParam(self, paramName, paramValue)
MusicController.setEventParam = new_setEventParam
"""

#SoundGroups.CUSTOM_MP3_EVENTS = tuple( list(SoundGroups.CUSTOM_MP3_EVENTS) + [SAMPLE_MP3] ) # see if soundgroups call is better?
SAMPLE_MP3 = "ROM_sample"
ROM_Available = {SAMPLE_MP3: False}

# function to run wwise's prepare event. Is identical to the ginstance version, since both cause ID not found.
def prepareMP3(event):
    if not ResMgr.isFile('audioww/%s.mp3' % event):
        print('ERROR SOUND: mp3 file does not exist', 'audioww/%s.mp3' % event)
        return False
    WWISE.WW_prepareMP3('%s.mp3' % event)
    return True

# override loadConfig to add concerning files
old__loadConfig = MusicController._MusicController__loadConfig
def new__loadConfig(self):
    old__loadConfig(self)
    # reupdate everything
    ROM_Available.update({k: prepareMP3(k) for k in ROM_Available.keys()})
    #print("Injected MusicController's loadConfig, availability dict: {}".format(ROM_Available))
    # try the other option: directly replace the data in cache
    if ROM_Available.get(SAMPLE_MP3, False):
        # print("[ROM] Debug: self.__soundEvents before change: {}".format(self._MusicController__soundEvents))
        sample = SoundGroups.g_instance.getSound2D(SAMPLE_MP3)
        self._MusicController__soundEvents[MUSIC_EVENT_COMBAT] = [sample]
        self._MusicController__soundEvents[MUSIC_EVENT_LOBBY] = [sample]
        # print("[ROM] Debug: self.__soundEvents after change: {}".format(self._MusicController__soundEvents))
        print("[ROM] rewriten in __soundEvents {} and {} by {}".format(MUSIC_EVENT_COMBAT, MUSIC_EVENT_LOBBY, sample))
MusicController._MusicController__loadConfig = new__loadConfig

# temporarily disable __updateOverridden to see if lobby will run the mp3 event.
# Still happen. must be some other function.
def do_nothing(self, *args):
    return
#MusicController._MusicController__updateOverridden = do_nothing

# main target - play event
# apparently not called very often.
old_MW_play = MusicController.play
def new_MW_play(self, eventId, params=None, checkIsPlaying=False):
    print("Injected in MusicController's play. eventId: {}, params: {}".format(eventId, params))
    if eventId == MUSIC_EVENT_COMBAT or eventId == MUSIC_EVENT_LOBBY:
        if checkIsPlaying and self._MusicController__music.isPlaying():
            # if flag is enabled, do not interfere with running music
            return
        # replace with custom mp3 if it exists. Use original flow if it doesn't
        if not ROM_Available.get(SAMPLE_MP3, False):
            return old_MW_play(self, eventId, params=params, checkIsPlaying=checkIsPlaying)
        newSoundEvent = SoundGroups.g_instance.getSound2D(SAMPLE_MP3)
        print("Debug mp3 exist @play, object is: {}".format(newSoundEvent))
        self._MusicController__music.replace(newSoundEvent, eventId, True)
        # alternative param arguments. Never showed up, but just to be sure
        if params is not None:
            for paramName, paramValue in params.iteritems():
                self.setEventParam(paramName, paramValue)
    else:
        return old_MW_play(self, eventId, params=params, checkIsPlaying=checkIsPlaying)
#MusicController.play = new_MW_play

# inject to create custom event when player health down
old_updateVehicleHealth = PlayerAvatar.updateVehicleHealth
def new_updateVehicleHealth(self, vehicleID, health, deathReasonID, isCrewActive, isRespawn):
    if vehicleID != self.playerVehicleID or not self.userSeesWorld():
        return
    print("Player health update @updateVehicleHealth: {}/{}".format(health, BigWorld.entities.get(self.playerVehicleID).maxHealth))
    return old_updateVehicleHealth(self, vehicleID, health, deathReasonID, isCrewActive, isRespawn)
PlayerAvatar.updateVehicleHealth = new_updateVehicleHealth
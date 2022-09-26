from ProjectileMover import ProjectileMover
import BigWorld, Math, constants, TriggersManager
from TriggersManager import TRIGGER_TYPE
import FlockManager
from vehicle_systems.tankStructure import TankPartNames, ColliderTypes
from helpers import gEffectsDisabled
from helpers.trajectory_drawer import TrajectoryDrawer
import traceback

old_addShot = ProjectileMover.add
def new_addShot(self, *args, **kwargs):
    attackerID = args[7] if len(args) > 7 else kwargs.get("attackerID", 0)
    if(attackerID == BigWorld.player().playerVehicleID): # own rounds only
        #traceback.print_stack()
        #print("Injected to ProjectileMover.add (player only); listing arguments: \nARGS: {}, \nKWARGS: {}".format(args, kwargs))
        # try duplicate the rounds
        old_addShot(self, *args, **kwargs)
        args = list(args)
        shotID, velocity = args[0], args[4]
        args[4] = Math.Vector3(-velocity[0], -velocity[1], -velocity[2]) # the duplicate should be completely reverted
        args[0] = shotID + 1
    return old_addShot(self, *args, **kwargs)
ProjectileMover.add = new_addShot
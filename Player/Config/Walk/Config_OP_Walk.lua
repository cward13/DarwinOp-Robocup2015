module(..., package.seeall); require('vector')
require 'unix'
-- Walk Parameters

walk = {};

----------------------------------------------
-- Stance and velocity limit values
----------------------------------------------
walk.stanceLimitX={-0.10,0.10};
walk.stanceLimitY={0.07,0.20};
walk.stanceLimitA={0*math.pi/180,30*math.pi/180};
--walk.velLimitX={-.03,.06};--reduced speed for stability
walk.velLimitX={-.03,.08};
walk.velLimitY={-.03,.03};
walk.velLimitA={-.4,.4};
walk.velDelta={0.02,0.02,0.15} 

----------------------------------------------
-- Stance parameters
---------------------------------------------
walk.bodyHeight = 0.295; 
walk.bodyTilt=15*math.pi/180; -- orig=20, 30 seems to be too much {spa}
walk.footX= -0.020; 
walk.footY = 0.035;
walk.supportX = 0;
walk.supportY = 0.010;
--walk.qLArm=math.pi/180*vector.new({90,8,-40});
--walk.qRArm=math.pi/180*vector.new({90,-8,-40});

walk.qLArm=math.pi/180*vector.new({90,2,-20});
walk.qRArm=math.pi/180*vector.new({90,-2,-20});

walk.qLArmKick=math.pi/180*vector.new({90,30,-60});
walk.qRArmKick=math.pi/180*vector.new({90,-30,-60});

walk.hardnessSupport = .5;
walk.hardnessSwing = 1;
walk.hardnessArm=.3;
---------------------------------------------
-- Gait parameters
---------------------------------------------
walk.tStep = 0.35;
walk.tZmp = 0.165;
walk.stepHeight = 0.045;    -- default: 0.035
walk.phSingle={0.1,0.9};

--------------------------------------------
-- Compensation parameters
--------------------------------------------
walk.hipRollCompensation = 4*math.pi/180;
walk.ankleMod = vector.new({-1,0})*1*math.pi/180;
walk.spreadComp = 0.015;

--------------------------------------------------------------
--Imu feedback parameters, alpha / gain / deadband / max
--------------------------------------------------------------
gyroFactor = 0.273*math.pi/180 * 300 / 1024; --dps to rad/s conversion

if Config.servo.pid==1 then
  walk.ankleImuParamX={0.5,0.3*gyroFactor,
                        1*math.pi/180, 25*math.pi/180};
  walk.kneeImuParamX={0.5,1.2*gyroFactor,
                        1*math.pi/180, 25*math.pi/180};
  walk.ankleImuParamY={0.5,0.7*gyroFactor,
                        1*math.pi/180, 25*math.pi/180};
  walk.hipImuParamY={0.5,0.3*gyroFactor,
                        1*math.pi/180, 25*math.pi/180};
  walk.armImuParamX={0.9,10*gyroFactor, 20*math.pi/180, 45*math.pi/180};

--  walk.armImuParamY={0.3,10*gyroFactor, 20*math.pi/180, 45*math.pi/180};

  --DISABLE Y BALANCING
  walk.armImuParamY={0.9,10*gyroFactor, 20*math.pi/180, 45*math.pi/180};

else
  walk.ankleImuParamX={0.9,0.3*gyroFactor, 0, 25*math.pi/180};
  walk.kneeImuParamX={0.9,1.2*gyroFactor, 0, 25*math.pi/180};
  walk.ankleImuParamY={0.9,0.7*gyroFactor, 0, 25*math.pi/180};
  walk.hipImuParamY={0.9,0.3*gyroFactor, 0, 25*math.pi/180};
  walk.armImuParamX={0.9,10*gyroFactor, 20*math.pi/180, 45*math.pi/180};
  walk.armImuParamY={0.9,10*gyroFactor, 20*math.pi/180, 45*math.pi/180};
end

--------------------------------------------
-- Support point modulation values
--------------------------------------------

walk.velFastForward = 0.05;
walk.velFastTurn = 0.15;

--walk.supportFront = 0.01; --Lean back when walking fast forward
walk.supportFront = 0.03; --Lean back when walking fast forward

walk.supportFront2 = 0.03; --Lean front when accelerating forward
walk.supportBack = -0.02; --Lean back when walking backward
walk.supportSideX = -0.01; --Lean back when sidestepping


walk.supportSideX = -0.005; --Lean back when sidestepping

walk.supportSideY = 0.02; --Lean sideways when sidestepping


walk.supportTurn = 0.02; --Lean front when turning


walk.turnCompThreshold = 0.1;
walk.turnComp = 0.005; --Lean front when turning

walk.turnComp = 0.003; --Lean front when turning


--------------------------------------------
-- WalkKick parameters
--------------------------------------------
walk.walkKickDef={}

--tStep stepType supportLeg stepHeight 
-- SupportMod shiftFactor footPos1 footPos2

walk.walkKickDef["FrontLeft"]={
  {0.30, 1, 0, 0.035 , {0,0}, 0.6, {0.06,0,0} },
  {0.40, 2, 1, 0.05 , {0.02,-0.02}, 0.5, {0.12,0,0}, {0.09,0,0} },
  {walk.tStep, 1, 0, 0.035 , {0,0}, 0.5, {0.04,0,0} },
}
walk.walkKickDef["FrontRight"]={
  {0.30, 1, 1, 0.035 , {0,0}, 0.4, {0.06,0,0} },
  {0.40, 2, 0, 0.05 , {0.02,0.02}, 0.5,  {0.12,0,0}, {0.09,0,0} },
  {walk.tStep, 1, 1, 0.035 , {0,0}, 0.5, {0.04,0,0} },
}
--Close-range walkkick (step back and then walkkick)
walk.walkKickDef["FrontLeft2"]={
  {0.30, 1, 1, 0.035 , {0,0}, 0.4, {-0.06,0,0} },
  {0.30, 1, 0, 0.035 , {0.02,0}, 0.6, {0.06,0,0} },
  {0.40, 2, 1, 0.05 , {0.0,-0.02}, 0.5, {0.12,0,0}, {0.09,0,0} },
  {walk.tStep, 1, 0, 0.035 , {0,0}, 0.5, {0.04,0,0} },
}
walk.walkKickDef["FrontRight2"]={
  {0.30, 1, 0, 0.035 , {0,0}, 0.6, {-0.06,0,0} },
  {0.30, 1, 1, 0.035 , {0.02,0}, 0.4, {0.06,0,0} },
  {0.40, 2, 0, 0.05 , {0.0,0.02}, 0.5,  {0.12,0,0}, {0.09,0,0} },
  {walk.tStep, 1, 1, 0.035 , {0,0}, 0.5, {0.04,0,0} },
}


--[[
walk.walkKickDef["SideLeft"]={
  {0.30, 1, 1, 0.035 , {0,0}, 0.4, {0.04,0.04,0} },
  {0.35, 3, 0, 0.07 , {-0.01,0.01}, 0.5, {0.06,-0.05,0},{0.09,0.005,0}},
  {0.25, 1, 1, 0.035 , {0,0}, 0.5, {0,0,0} },}

walk.walkKickDef["SideRight"]={
  {0.30, 1, 0, 0.035 , {0,0}, 0.6, {0.04,-0.04,0} },
  {0.35, 3, 1, 0.07 , {-0.01,-0.01},0.5, {0.06,0.05,0},{0.09,-0.005,0}},
  {0.25, 1, 0, 0.035 , {0,0},0.5,  {0,0,0} },
}
--]]
--Short-range walking sidekick
walk.walkKickDef["SideLeft"]={
  {0.30, 1, 1, 0.035 , {0,0}, 0.4, {0.0,0.04,0} },
  {0.35, 3, 0, 0.05 , {-0.01,0.01}, 0.5, {0.06,-0.05,0},{0.09,0.005,0}},
  {0.25, 1, 1, 0.035 , {0.01,0}, 0.5, {0,0,0} },}

walk.walkKickDef["SideRight"]={
  {0.30, 1, 0, 0.035 , {0,0}, 0.6, {0.0,-0.04,0} },
  {0.35, 3, 1, 0.05 , {-0.01,-0.01},0.5, {0.06,0.05,0},{0.09,-0.005,0}},
  {0.25, 1, 0, 0.035 , {0.01,0},0.5,  {0,0,0} },
}


--With more sweep
walk.walkKickDef["SideLeft"]={
  {0.30, 1, 1, 0.035 , {0,0}, 0.4, {0.0,0.04,10*math.pi/180} },
  {0.35, 3, 0, 0.05 , {0.01,0.01}, 0.5, 
	{0.06,-0.05,-20*math.pi/180},{0.09,0.005,0}},
  {0.25, 1, 1, 0.035 , {0.01,0}, 0.5, {0,0,0} },}

walk.walkKickDef["SideRight"]={
  {0.30, 1, 0, 0.035 , {0,0}, 0.6, {0.0,-0.04,-10*math.pi/180} },
  {0.35, 3, 1, 0.05 , {0.01,-0.01},0.5, 
	{0.06,0.05,20*math.pi/180},{0.09,-0.005,0}},
  {0.25, 1, 0, 0.035 , {0.01,0},0.5,  {0,0,0} },
}



-- tStep stepType supportLeg stepHeight 
-- SupportMod shiftFactor footPos1 footPos2
-- Boxing walk kick
walk.walkKickDef["PunchLeft"]={
  {0.60, 1, 0, 0.035 , {0,0}, 0.7, {0,0,0} },
  {0.60, 2, 1, 0.07 , {0.02,-0.02}, 0.5, {0,0,0}, {0,0,0} },
  {walk.tStep, 1, 0, 0.035 , {0,0}, 0.5, {0,0,0} },
}
walk.walkKickDef["PunchRight"]={
  {0.60, 1, 1, 0.035 , {0,0}, 0.3, {0,0,0} },
  {0.60, 2, 0, 0.07 , {0.02,0.02}, 0.5,  {0,0,0}, {0,0,0} },
  {walk.tStep, 1, 1, 0.035 , {0,0}, 0.5, {0,0,0} },
}


walk.walkKickPh=0.5;

--------------------------------------------
-- Robot - specific calibration parameters
--------------------------------------------

walk.kickXComp = 0;
walk.supportCompL = {0,0,0};
walk.supportCompR = {0,0,0};
walk.servoBias = {0,0,0,0,0,0,0,0,0,0,0,0};
walk.footXComp = 0;
walk.footYComp = 0;

--Default pitch angle offset of OP 
walk.headPitchBias = 40* math.pi / 180; 
walk.headPitchBiasComp = 0;

local robotName = unix.gethostname();
local robotID = 0;

--Load robot specific calibration value
require('calibration');
if calibration.cal and calibration.cal[robotName] then
  walk.supportCompL = calibration.cal[robotName].supportCompL; -- added by david
  walk.supportCompR = calibration.cal[robotName].supportCompR; -- added by David
  walk.servoBias = calibration.cal[robotName].servoBias;
  walk.footXComp = calibration.cal[robotName].footXComp;
  walk.footYComp = calibration.cal[robotName].footYComp; -- added by david
  walk.kickXComp = calibration.cal[robotName].kickXComp;
  walk.kickYComp = calibration.cal[robotName].kickYComp;
  walk.headPitchBiasComp = calibration.cal[robotName].headPitchBiasComp;
  print(robotName.." walk parameters loaded")
end














------------------------------------------------
-- Upper body motion keyframes
-----------------------------------------------
-- tDuration qLArm qRArm bodyRot
walk.motionDef={};

walk.motionDef["hurray1"]={
 {1.0,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},  --possibility: duration, {pitch, roll, elbow}, {pitch, roll, elbow}
        {40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.4,{-30*math.pi/180, 30*math.pi/180, -90*math.pi/180},
        {-30*math.pi/180,-30*math.pi/180,-90*math.pi/180}},
 {0.4,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
        {40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.4,{-30*math.pi/180, 30*math.pi/180, -90*math.pi/180},
        {-30*math.pi/180,-30*math.pi/180,-90*math.pi/180}},
 {0.4,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
        {40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.4,{-30*math.pi/180, 30*math.pi/180, -90*math.pi/180},
        {-30*math.pi/180,-30*math.pi/180,-90*math.pi/180}},
 {1.0,{90*math.pi/180, 8*math.pi/180,-40*math.pi/180},
        {90*math.pi/180, -8*math.pi/180,-40*math.pi/180}}
} 

--pointing up
walk.motionDef["point"]={
 {1.0,{-40*math.pi/180, 50*math.pi/180, 0*math.pi/180},
        {160*math.pi/180,-60*math.pi/180,-90*math.pi/180},
        {20*math.pi/180,0*math.pi/180,-20*math.pi/180}},

 {3.0,{-40*math.pi/180, 50*math.pi/180, 0*math.pi/180},
        {160*math.pi/180,-60*math.pi/180,-90*math.pi/180},
        {20*math.pi/180,0*math.pi/180,-20*math.pi/180}},

 {1.0,{90*math.pi/180, 8*math.pi/180,-40*math.pi/180},
        {90*math.pi/180, -8*math.pi/180,-40*math.pi/180},
        {0,20*math.pi/180,0}}
} 


--Two arm punching up
walk.motionDef["hurray2"]={
 {0.5,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
        {40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},

 {0.2, {40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
        {-30*math.pi/180,-30*math.pi/180,-90*math.pi/180}},
 {0.2,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
        {40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.2,{-30*math.pi/180, 30*math.pi/180, -90*math.pi/180},
        {40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.2,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
        {40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},

 {0.2, {40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
        {-30*math.pi/180,-30*math.pi/180,-90*math.pi/180}},
 {0.2,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
        {40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.2,{-30*math.pi/180, 30*math.pi/180, -90*math.pi/180},
        {40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},
 {0.2,{40*math.pi/180, 20*math.pi/180, -140*math.pi/180},
        {40*math.pi/180,-20*math.pi/180,-140*math.pi/180}},

 {0.5,{90*math.pi/180, 8*math.pi/180,-40*math.pi/180},
        {90*math.pi/180, -8*math.pi/180,-40*math.pi/180}}
} 


--Two arm side swing
walk.motionDef["swing"]={
 {0.5,{90*math.pi/180, 90*math.pi/180, -40*math.pi/180},
        {90*math.pi/180,-90*math.pi/180,-40*math.pi/180},
        {0*math.pi/180,20*math.pi/180,-20*math.pi/180}},

 {0.5,{90*math.pi/180, 90*math.pi/180, -40*math.pi/180},
        {90*math.pi/180,-90*math.pi/180,-40*math.pi/180},
        {0*math.pi/180,20*math.pi/180,20*math.pi/180}},

 {0.5,{90*math.pi/180, 90*math.pi/180, -40*math.pi/180},
        {90*math.pi/180,-90*math.pi/180,-40*math.pi/180},
        {0*math.pi/180,20*math.pi/180,-20*math.pi/180}},

 {0.5,{90*math.pi/180, 8*math.pi/180,-40*math.pi/180},
        {90*math.pi/180, -8*math.pi/180,-40*math.pi/180},
        {0*math.pi/180,20*math.pi/180,0*math.pi/180}}
} 




--One-Two Punching
walk.motionDef["2punch"]={
 {0.2,{90*math.pi/180, 40*math.pi/180, -160*math.pi/180},
        {90*math.pi/180,-40*math.pi/180,-160*math.pi/180},
        {0*math.pi/180,20*math.pi/180,0*math.pi/180}},

 {0.2,{90*math.pi/180, 30*math.pi/180, -160*math.pi/180},
        {90*math.pi/180,-30*math.pi/180,-160*math.pi/180},
        {0*math.pi/180,20*math.pi/180,20*math.pi/180}},
 {0.2,{90*math.pi/180, 30*math.pi/180, -160*math.pi/180},
        {90*math.pi/180,-30*math.pi/180,-160*math.pi/180},
        {0*math.pi/180,20*math.pi/180,20*math.pi/180}},

 --right jab
 {0.2,{90*math.pi/180, 30*math.pi/180, -160*math.pi/180},
        {-20*math.pi/180,-30*math.pi/180,0*math.pi/180},
        {0*math.pi/180,20*math.pi/180,20*math.pi/180}},

--left straignt
 {0.3,{-20*math.pi/180, 20*math.pi/180, 0*math.pi/180},
        {90*math.pi/180,-40*math.pi/180,-160*math.pi/180},
        {0*math.pi/180,20*math.pi/180,-30*math.pi/180}},

--retract
 {0.2,{90*math.pi/180, 40*math.pi/180, -160*math.pi/180},
        {90*math.pi/180,-40*math.pi/180,-160*math.pi/180},
        {0*math.pi/180,20*math.pi/180,-30*math.pi/180}},
 {0.3,{90*math.pi/180, 8*math.pi/180,-40*math.pi/180},
        {90*math.pi/180, -8*math.pi/180,-40*math.pi/180},
        {0*math.pi/180,20*math.pi/180,0*math.pi/180}}
} 

walk.motionDef["jabright"]={
  --right jab
  {0.2,
    {90*math.pi/180, 30*math.pi/180, -160*math.pi/180},
    {-20*math.pi/180,-30*math.pi/180,0*math.pi/180},
  },
  --retract
  {0.2,
    {90*math.pi/180, 40*math.pi/180, -160*math.pi/180},
    {90*math.pi/180,-40*math.pi/180,-160*math.pi/180},
  },
}

walk.motionDef["jableft"]={
  --right jab
  {0.2,
    {-20*math.pi/180, 30*math.pi/180, 0*math.pi/180},
    {90*math.pi/180,-40*math.pi/180,-160*math.pi/180},
  },
  --retract
  {0.2,
    {90*math.pi/180, 40*math.pi/180, -160*math.pi/180},
    {90*math.pi/180,-40*math.pi/180,-160*math.pi/180},
  },
}

-- test1 behavior


walk.motionDef["prePick"] = {
  {1.0,
    {90*math.pi/180, 10*math.pi/180, -20*math.pi/180},
    {90*math.pi/180, -10*math.pi/180, -20*math.pi/180},
    {0*math.pi/180,60*math.pi/180,0*math.pi/180}
  },

  {1.0,
    {90*math.pi/180, 8*math.pi/180, -20*math.pi/180},
    {90*math.pi/180, -8*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 20*math.pi/180, 0*math.pi/180}
  }
}

walk.motionDef["pickupLow"]={

  {1.0,
    {90*math.pi/180, 10*math.pi/180, -20*math.pi/180},
    {90*math.pi/180, -10*math.pi/180, -20*math.pi/180},
    {0*math.pi/180,60*math.pi/180,0*math.pi/180}
  },

  {1.0,
    {10*math.pi/180, 10*math.pi/180, -20*math.pi/180},
    {10*math.pi/180, -10*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 60*math.pi/180, 0*math.pi/180}
  },
  
   -- pick  
  {1.0,
    {10*math.pi/180, -15*math.pi/180, -20*math.pi/180},
    {10*math.pi/180, 15*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 60*math.pi/180, 0*math.pi/180}
  },

  -- stand up 
  {1.0,
    {20*math.pi/180, -15*math.pi/180, -20*math.pi/180},
    {20*math.pi/180, 15*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 5*math.pi/180,0*math.pi/180}
  },

--[[ 
 -- hold for 10 s 
  {10.0,
    {20*math.pi/180, -15*math.pi/180, -20*math.pi/180},
    {20*math.pi/180, 15*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 20*math.pi/180,0*math.pi/180}
  },

  -- drop 
  {1.0,
    {10*math.pi/180, 8*math.pi/180, -20*math.pi/180},
    {10*math.pi/180, -8*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 20*math.pi/180,0*math.pi/180}
  },
  
  {1.0,
    {90*math.pi/180, 8*math.pi/180, -20*math.pi/180},
    {90*math.pi/180, -8*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 20*math.pi/180, 0*math.pi/180}
  }
]]--
} 

walk.motionDef["pickupHigh"]={

  {2.0,
    {90*math.pi/180, 10*math.pi/180, -20*math.pi/180},
    {90*math.pi/180, -10*math.pi/180, -20*math.pi/180},
    {0*math.pi/180,60*math.pi/180,0*math.pi/180}
  },

  {1.0,
    {10*math.pi/180, 10*math.pi/180,-20*math.pi/180},
    {10*math.pi/180, -10*math.pi/180, -20*math.pi/180},
    {0*math.pi/180,60*math.pi/180,0*math.pi/180}
  },

   -- pick
  {1.0,
    {10*math.pi/180, -15*math.pi/180, -20*math.pi/180},
    {10*math.pi/180, 15*math.pi/180, -20*math.pi/180},
    {0*math.pi/180,60*math.pi/180,0*math.pi/180}
  },

-- stand up   
  {2.0,
    {-60*math.pi/180, -15*math.pi/180, -20*math.pi/180},
    {-60*math.pi/180, 15*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 10*math.pi/180,0*math.pi/180}
  },

--[[
 -- hold for 10 s 
  {10.0,
    {-60*math.pi/180, -15*math.pi/180, -20*math.pi/180},
    {-60*math.pi/180, 15*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 20*math.pi/180,0*math.pi/180}
  },

  -- drop 
  {1.0,
    {10*math.pi/180, 8*math.pi/180, -20*math.pi/180},
    {10*math.pi/180, -8*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 20*math.pi/180,0*math.pi/180}
  },

  {1.0,
    {90*math.pi/180, 8*math.pi/180, -20*math.pi/180},
    {90*math.pi/180, -8*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 20*math.pi/180, 0*math.pi/180}
  }
]]--

}


walk.motionDef["drop"]={

  {2.0,
    {0*math.pi/180, -15*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 15*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 20*math.pi/180, 0*math.pi/180}
  },

--[[  {2.0,
    {30*math.pi/180, -10*math.pi/180, -20*math.pi/180},
    {30*math.pi/180, 10*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 20*math.pi/180, 0*math.pi/180}
  },
]]--

  {2.0,
    {90*math.pi/180, 8*math.pi/180, -20*math.pi/180},
    {90*math.pi/180, -8*math.pi/180, -20*math.pi/180},
    {0*math.pi/180, 20*math.pi/180, 0*math.pi/180}    
  },
}


walk.walkKickSupportMod = {{0,0},{0,0}}




--ZMP-preview step definitions
zmpstep = {};

zmpstep.bodyHeight = 0.295; 
zmpstep.bodyTilt = 23*math.pi/180;-- modified this too, origional was 20
zmpstep.tZmp = 0.165;

zmpstep.stepHeight = 0.035;
zmpstep.phSingle={0.1,0.9};  --
zmpstep.hipRollCompensation = 3*math.pi/180;

zmpstep.supportX = 0.0;
zmpstep.supportY = 0.02;

zmpstep.motionDef={};



zmpstep.params = true;
zmpstep.param_k1_px={-826.152540,-303.478776,-33.247242}
zmpstep.param_a={
  {1.000000,0.010000,0.000050},
  {0.000000,1.000000,0.010000},
  {0.000000,0.000000,1.000000},
}
zmpstep.param_b={0.000000,0.000050,0.010000,0.010000}
zmpstep.param_k1={
    185.714242,120.443259,71.400488,34.823349,7.805849,
    -11.895432,-26.011485,-35.877042,-42.520477,-46.733353,
    -49.124239,-50.160332,-50.199666,-49.516014,-48.318153,
    -46.764757,-44.975909,-43.042004,-41.030621,-38.991837,
    -36.962325,-34.968520,-33.029059,-31.156661,-29.359574,
    -27.642690,-26.008398,-24.457241,-22.988416,-21.600159,
    -20.290035,-19.055155,-17.892348,-16.798283,-15.769559,
    -14.802778,-13.894588,-13.041723,-12.241025,-11.489461,
    -10.784129,-10.122268,-9.501256,-8.918610,-8.371986,
    -7.859169,-7.378076,-6.926745,-6.503330,-6.106098,
    -5.733420,-5.383770,-5.055712,-4.747901,-4.459077,
    -4.188056,-3.933728,-3.695054,-3.471061,-3.260833,
    -3.063515,-2.878305,-2.704450,-2.541245,-2.388030,
    -2.244185,-2.109130,-1.982321,-1.863247,-1.751431,
    -1.646425,-1.547807,-1.455185,-1.368189,-1.286472,
    -1.209709,-1.137597,-1.069849,-1.006198,-0.946392,
    -0.890196,-0.837388,-0.787761,-0.741120,-0.697283,
    -0.656078,-0.617345,-0.580932,-0.546697,-0.514508,
    -0.484239,-0.455773,-0.429000,-0.403815,-0.380123,
    -0.357830,-0.336851,-0.317105,-0.298516,-0.281012,
    -0.264525,-0.248992,-0.234353,-0.220550,-0.207531,
    -0.195245,-0.183645,-0.172684,-0.162321,-0.152514,
    -0.143225,-0.134417,-0.126056,-0.118108,-0.110541,
    -0.103324,-0.096430,-0.089831,-0.083498,-0.077409,
    -0.071538,-0.065863,-0.060363,-0.055019,-0.049812,
    -0.044729,-0.039756,-0.034885,-0.030113,-0.025442,
    -0.020883,-0.016457,-0.012197,-0.008157,-0.004410,
    -0.001061,0.001747,0.003821,0.004903,0.004650,
    0.002610,-0.001812,-0.009393,-0.021152,-0.038414,
    -0.062904,-0.096865,-0.143208,-0.205710,-0.289267,
    }



--Supportfoot relstep zmpmod duration steptype

zmpstep.motionDef["nonstop_kick_left"]={
  support_start = 0, --Left support 
  stepDef={  
    {0, {0.06,0,0}    ,{0.02,0},0.25}, --LS step  
    {2, {0,0,0}       ,{0.02,0},0.05}, --DS step

    {1, {0,-0.01,0}   ,{0.02,-0.01},0.2,1}, --RS step, lifting
    {1, {0.18,0,0}    ,{0.02,-0.01},0.2,2}, --RS step  kicking
    {1, {-0.06,0.01,0},{0.01,0.0},0.1,3}, --RS step  returning
    {1, {0.0,0,0}     ,{0.00,0.0},0.1,4}, --RS step  landing
    {2, {0,0,0}       ,{0.005,0},   0.07}, --DS step
    {0, {0.06,0.0,0}    ,{0.005,0},0.25}, --LS step  
--------------------------------------------------------------

    {1, {0.0,0,0},{0,0},0.25,9}, --LS step  
    {0, {0.0,0,0},{0,0},0.25}, --LS step  
    {1, {0.0,0,0},{0,0},0.25}, --LS step  
    {0, {0.0,0,0},{0,0},0.25}, --LS step  
    {2, {0,0,0},{0,0},0.25}, --DS step
    {2, {0,0,0},{0,0},0.05}, --DS step
  },
  support_end = 1, --Next RS step
}

zmpstep.motionDef["nonstop_kick_right"]={
  support_start = 1, --Right support 
  stepDef={  
    {1, {0.06,0.0,0}   ,{0.02,0},0.25}, --RS step  
    {2, {0,0,0}        ,{0.02,0},0.05}, --DS step
    {0, {0,0.01,0}     ,{0.02,0.01},0.2,1}, --LS step, lifting
    {0, {0.18,0,0}     ,{0.02,0.01},0.2,2}, --LS step  kicking
    {0, {-0.06,-0.01,0},{0.01,0.0},0.1,3}, --LS step  returning
    {0, {0.0,0,0}      ,{0.00,0.0},0.1,4}, --LS step  landing
    {2, {0,0,0}        ,{0.005,0.0},  0.07}, --DS step
    {1, {0.06,0.0,0}  ,{0.005,0},0.25}, --RS step  
---------------------------------------------------------------

    {0, {0.0,0,0},{0,0},0.25,9}, --LS step  
    {1, {0.0,0,0},{0,0},0.25}, --LS step  
    {0, {0.0,0,0},{0,0},0.25}, --LS step  
    {1, {0.0,0,0},{0,0},0.25}, --LS step  
    {2, {0,0,0},{0,0},0.5}, --DS step
    {2, {0,0,0},{0,0},0.05,9}, --DS step
  },
  support_end = 0, --next LS step
}








-------------------------------------------------------------------
-- Little more slow stepkick (wait a bit after landing)
-------------------------------------------------------------------

zmpstep.motionDef["nonstop_kick_left"]={
  support_start = 0, --Left support 
  stepDef={  
    {0, {0.06,0,0}    ,{0.02,0},0.25}, --LS step  
    {2, {0,0,0}       ,{0.02,0},0.05}, --DS step

    {1, {0,-0.01,0}   ,{0.02,-0.01},0.2,1}, --RS step, lifting
    {1, {0.18,0,0}    ,{0.02,-0.01},0.2,2}, --RS step  kicking
--[[
    {1, {-0.06,0.01,0},{0.01,0.0},0.1,3}, --RS step  returning
    {1, {0.0,0,0}     ,{0.00,0.0},0.1,4}, --RS step  landing
    {2, {0,0,0}       ,{0.005,0},   0.30}, --DS step
--]]

    {1, {-0.06,0.01,0},{-0.01, 0.0},0.1,3}, --RS step  returning
    {1, {0.0,0,0}     ,{-0.01, 0.0},0.1,4}, --RS step  landing
    {2, {0,0,0}       ,{-0.01, 0.0},   0.30}, --DS step

    {0, {0.06,0.0,0}    ,{0.005,0},0.25}, --LS step  
--------------------------------------------------------------

    {1, {0.0,0,0},{0,0},0.25,9}, --LS step  
    {0, {0.0,0,0},{0,0},0.25}, --LS step  
    {1, {0.0,0,0},{0,0},0.25}, --LS step  
    {0, {0.0,0,0},{0,0},0.25}, --LS step  
    {2, {0,0,0},{0,0},0.25}, --DS step
    {2, {0,0,0},{0,0},0.05}, --DS step
  },
  support_end = 1, --Next RS step
}

zmpstep.motionDef["nonstop_kick_right"]={
  support_start = 1, --Right support 
  stepDef={  
    {1, {0.06,0.0,0}   ,{0.02,0},0.25}, --RS step  
    {2, {0,0,0}        ,{0.02,0},0.05}, --DS step
    {0, {0,0.01,0}     ,{0.02,0.01},0.2,1}, --LS step, lifting
    {0, {0.18,0,0}     ,{0.02,0.01},0.2,2}, --LS step  kicking
--[[
    {0, {-0.06,-0.01,0},{0.01,0.0},0.1,3}, --LS step  returning
    {0, {0.0,0,0}      ,{0.00,0.0},0.1,4}, --LS step  landing
    {2, {0,0,0}        ,{0.005,0.0},  0.30}, --DS step
--]]

    {0, {-0.06,-0.01,0},{-0.01, 0.0},0.1,3}, --LS step  returning
    {0, {0.0,0,0}      ,{-0.01, 0.0},0.1,4}, --LS step  landing
    {2, {0,0,0}        ,{-0.01, 0.0},  0.30}, --DS step


    {1, {0.06,0.0,0}  ,{0.005,0},0.25}, --RS step  
---------------------------------------------------------------

    {0, {0.0,0,0},{0,0},0.25,9}, --LS step  
    {1, {0.0,0,0},{0,0},0.25}, --LS step  
    {0, {0.0,0,0},{0,0},0.25}, --LS step  
    {1, {0.0,0,0},{0,0},0.25}, --LS step  
    {2, {0,0,0},{0,0},0.5}, --DS step
    {2, {0,0,0},{0,0},0.05,9}, --DS step
  },
  support_end = 0, --next LS step
}


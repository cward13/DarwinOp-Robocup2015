--[[
HFA.LUA
Sean Luke
Version 1.0
May 2014


A simple package to make it easy to implement hierarchical finite-state
automata or HFA in the form of Moore machines, for purposes of programming
agent behaviors.  This package is not as useful for automata which are intended
for lexing strings.  An HFA is a finite-state automaton whose states correspond
to basic behaviors (a hard-coded behavior you have constructed) or to other 
automata.  While HFA contain other HFA, HFA are not permitted to be recursive: 
that is, you cannot have an HFA which ultimately contains itself.



-- Behaviors --

Let's begin with the notion of a BEHAVIOR.  A behavior is a simple object 
(a dictionary) which contains a few things:

1. A NAME (as a string).  This really only exists for debugging (for now).
2. A backpointer to a PARENT of the behavior (or to nil if there is no parent).
   This item may get changed dynamically to various things as the automaton
   is running.  Before any of the functions below (start/stop/go) are called,
   the PARENT will have been set.
3. A START function.  This function is called when the behavior is started.
   The function takes two arguments, the first of which is the behavior itself.
   This value may be nil.  The second is a table of targets.  We'll get to these
   later in the TARGETS section, for now set them to NIL.
4. A GO function.  This function is called immediately after START, and
   rapidly / repeatedly thereafter.  The function takes a single argument,
   the first of which is the behavior itself.  This value may be nil.
   The second is a table of targets.  We'll get to these later in the TARGETS 
   section, for now set them to NIL.
5. A STOP function.  This function is called when the behavior is stopped.
   The function takes a single argument, the first of which is the behavior itself.
   After being stopped, a behavior can be started again.  This value may be nil.
   The second is a table of targets.  We'll get to these later in the TARGETS 
   section, for now set them to NIL.
5. Whether the behavior has yet been PULSED.  This is used by the pulse function.


Imagine you had a behavior called myBehavior.  Then you could access these as:

myBehavior.name
myBehavior.parent
myBehavior.pulsed
myBehavior.start
myBehavior.stop
myBehavior.go

A BASIC BEHAVIOR is a hard-coded behavior you have created yourself.  You don't
have to implement all three functions (start/stop/go).  For example, if you have
a one-shot behavior (like "kickBall"), you might implement it by simply providing
the start function (to kick the ball) and setting the other functions to nil.
Or if you have a continuous function (like "forward"), you might do this by
providing a go function (to move the robot forward by an epsilon), and set
the others to nil.  Or if you have an asynchronous behavior (like "walk"),
you might implement the start function to tell the robot to begin walking,
set the go function to nil, and set the stop function to tell the robot to stop
walking.  And so on.

A utility function is provided to you to make this easy:

makeBehavior(name, start, stop, go)           returns a behavior.

In most cases you'd store the behavior in a global variable with the same name.  So
if you were creating a behavior called FOO, you'd do so like this:

foo = makeBehavior("foo", ... )
                
                                      
                                 
-- Automata --

An HFA is a behavior associated with a set of SUB-BEHAVIORS in the form of STATES.
For purposes of this library, a state and a behavior are the same thing.  At any 
time, an active HFA has a CURRENT STATE (that is, a current sub-behavior).  There 
is a special initial state called START (not to be confused with the start
function).  This is the only state which is not a behavior: it is actually just
the string "start".  Thus we have (for some HFA called myHFA):

myHFA.name            (Because an hfa is a behavior)
myHFA.parent        (Likewise)
myHFA.pulsed		(Likewise)
myHFA.start            (Likewise.  Set to startHFA, see below.)
myHFA.stop            (Likewise.  Set to stopHFA, see below.)
myHFA.go            (Likewise.  Set to goHFA, see below.)
myHFA.current        (The current state)

An HFA is associated with a TRANSITION FUNCTION which takes the HFA as an 
argument and returns what the current state ought to be at this time.  This is
typically done by examining the present setting of the current state and some 
world information to determine the new current state.  More on transition
functions in a bit, but for the moment, note that the transition functino is
stored here:

myHFA.transition

Because an HFA is a behavior, it has a start, stop and go function stored.  All
HFA use exactly the same start, stop, and go functions, and so when you make an HFA
you don't provide them: the HFA set them up themselves.  These special private
functions are called startHFA(...), stopHFA(...), and goHFA(...).

The startHFA(...) function initializes the current state of the HFA to the START
state, among other things.

The stopHFA(...) function sets the current state of the HFA to nil, among other
things.  If the current state wasn't already nil or the "start" state, then its
STOP function is also called recursively.

The goHFA(...) function is where the interesting work is done.  This function first
calls the transition function to determine the new current state.  If the current
state is different from the previous one, then the START function is called on the
new current state, and furthermore if the previous current state wasn't nil and 
wasn't "start", then the previous current state's STOP function is also called.
Regardless, the current state is changed, and GO function is then called on the
new current state.

Notice that in goHFA(...) the transition function is called FIRST, followed by 
the GO function (and possibly START and STOP).  This means that the "start" 
state never has its GO function called, ever.  This is intentional.  The "start"
state is just meant to be a dummy state which provides us with a way to define
a transition funtion which, in essence, will specify the initial behavior performed
by the HFA.  That's why the "start" state isn't even a behavior: it's just the
string "start".  It's defined in the global variable:

start = "start"

Also notice that the HFA doesn't actually store any of its sub-behaviors.  They're
just specified by the transition function based on the current state of the HFA.
 
HFA are created with a different utility function than basic hard-coded behaviors.
You call makeHFA, providing the name, the transition function.  

makeHFA(name, transition)           returns an HFA.

Again, when creating an HFA, you'd typically store it in a global variable of the
same name as the HFA, thus if you were creating an HFA called FOO, you'd say:

foo = makeHFA("foo", ... )



-- Transition Functions --

Transition functions for automata can be complex: they subsume all the edges in the
finite-state automaton.  It'd be very inconvenient to have to write a transition
function on your own.  Two items are provided to make this easier on you.

First, there is utility function makeTransition(...).  This function takes a single
argument, TRANSITIONS, which is a dictionary.  The KEYS of the dictionary
are behaviors.  The VALUES are either BEHAVIORS or are themselves TRANSITION FUNCTIONS
(which, as normal, take the HFA as a single argument and return a desired new current
state).

makeTransition(transitions, nil)                returns a transition function

The function generated by makeTransition(...) works like this.  When called to
determine the next current state, it queries the HFA for the present current state.
It then looks that state up in the dictionary as the key.  If the resulting value is
a behavior, this behavior is returned as the new current state.  If the resulting
value is a transition function, this function is called and its return value is returned
as the new current state.

Thus every state in the HFA can have its own transition function which says where
to go next if you're presently in that state; or it can explicitly declare another state
to unilaterally go to next.  This second case is equivalent to an unlabeled (or "epsilon")
edge in an FSA.

Thus the most common pattern for making an HFA called FOO would be:

foo = makeHFA("foo", makeTransition(...))

For example, you might have something like this.  See if you can make out what's going on:

foo = makeHFA("foo", makeTransition(
    {
    [start] = forward,
    [forward] = function(hfa) if (closeToBall()) then return kick else return forward end end,
    [kick] = rotate,
    [rotate] = function(hfa) if (ballAhead()) then return forward else return rotate end end,
    }))

Second, you can create behaviors which specify their own transitions.  More specifically,
if a behavior is the current state, and that behavior's GO function returns a behavior
as its return value, this new behavior will be treated as the next current state.  Though
you'd never access this, the return value of the GO function is stored here.

myHFA.goReturnValue

This second feature can be convenient, but it has two drawbacks.  First, it means that
your behavior is no longer necessarily modular: it can no longer be easily used in 
different contexts in different HFA.  Second, even if you use this gizmo for all of your
behaviors, you still have to specify the transition function for the "start" state.

Note that the transition function takes precedence over this second feature.   Even if
your behavior takes advantage of this second feature in its GO function, if you specify
a transition for the behavior in your transition function, the transition will be used
instead.

If you do not specify a transition function, or your transition function does not 
have a transition for a specific current state and that behavior returns nothing, then
no transition is made: the behavior stays the current state.  No warning is issued.



-- Running the HFA --

So you've constructed a hierarchy of automata and basic behaviors.  How do you get the
whole thing going?  With the utility function PULSE(...)

pulse(behavior, targets)    initially calls START on the behavior, then GO.  Thereafter
                            just calls GO on the behavior.
                            
(for now, set targets to nil -- we'll get to them later in the TARGETS section)_

Typically you'd just set up your HFA and then call pulse(...) on it forever.  If for 
some reason you need to reset the HFA after calling pulse(...) on it some number of times,
you can do so with the following function:

reset(behavior, targets)	calls STOP on the behavior, then resets it so pulse will
							call START on it again in the future.

Example:

pulse(myHFA, myTargets)
pulse(myHFA, myTargets)
pulse(myHFA, myTargets)
-- ... and so on, then to reset:
reset(myHFA, myTargets)
-- we're now ready to begin pulsing again...



-- Flags --

HFA come with a variety of gizmos which you will probably find convenient.  Foremost
are FLAGS, which permit a child HFA to inform its parent HFA that it believes it
has completed its task ("done") or that it has "failed".  A flag is set by the
child behavior transitioning to a FLAG BEHAVIOR as its current state.  When this happens,
the corresponding flag is set in the *parent* (not the child).  The parent's transition
functions can test for this flag to determine whether they should now transition away from
the child as the parent's current state, and go somewhere else.  Flags are reset when
startHFA(...) is called on the parent and also when the parent's goHFA(...) function
transitions to a new current state.

There are four flag behaviors available:

done        raises the "done" flag and immediately transitions to the "start" state
failed        raises the "failed" flag and immediately transitions to the "start" state
sayDone        raises the "done" flag
sayFailed    raises the "failed" flag

The first two are the most common, since once you're done (or have failed) you probably
have no further actions you want to do and might as well start over from the top if for
some reason your parent HFA doesn't act on this flag being raised.  For
these two, there's no reason to declare a transition since the transition is
automatic.  For the second two (setDone, setFailed), you need to provide a transition
of some kind, typically a unilateral one.  These second two are much less common.

The flags themselves are stored in the parent here (you'll rarely touch this):

myHFA.done            (false by default)
myHFA.failed        (false by default)

Flags may be PROPAGATED.  It's a common pattern in building HFA that you see transition
functions of the form "if DONE has been rased, then transition to DONE".   This is
essentially saying "If my child thinks he's done, then I'm done too." (likewise "failed").
Because it's so common, rather than require this transition, an HFA can declare that all
of its flags should be propagated to its parent.  This means that if its child sets a flag
in the HFA, the same flag will immediateliy be set in the HFA's parent.  If the parent
likewise has propagation set, it'll be set in the grandparent too, and so on.  If this
feels like throwing an exception, you're on the right track.

You set propagation in your hfa like this:

myHFA.propagateFlags = true

There is an internal function used by the various flag behaviors to set the appropriate
flag and also potentially propagate it recursively:

setFlag(hfa, flag)        sets the given flag in the HFA.  Example: setFlag(myHFA, "failed")



-- COUNTERS AND TIMERS --

Each HFA also has one COUNTER and one TIMER.  HFA nested within one another do not share
these: they have separate counters and timers.

A COUNTER is just an integer which starts at zero (when the HFA's startHFA(...) function is
called) and may be increased or reset to zero by certain behaviors which the HFA may
transition to as its current state.  These behaviors are:

bumpCounter            increments the counter by 1
resetCounter        sets the counter to 0

The current counter value is stored here:

myHFA.counter

... but it's better style to test the current counter value like this:

currentCounter(myHFA)

Testing the value of a counter is useful in a transition function.  Let's say that
you wanted to go forward for three steps and if you were still not close enough
to the ball, you transferred to the run state, then go back to forward.  You might say:

foo = makeHFA("foo", makeTransition(
    {
    [start] = forward,
    [forward] = function(hfa) if (closeToBall()) then return kick else return bumpCounter end end,
    [kick] = rotate,
    [rotate] = function(hfa) if (ballAhead()) then return forward else return rotate end end,
    [bumpCounter] = function(hfa) if (hfa.counter > 3) then return run else return forward end end,
    [run] = resetCounter,
    [resetCounter] = forward,
    }))
    
Similarly, a TIMER is an integer which stores a time interval in seconds.  When the HFA's
startHFA(...) function is called, the timer is set to the current time.  A single behavior
can likewise update the timer to the current time:

resetTimer            updates the timer to the current time

The current timer value is stored here:

myHFA.timer

... but almost certainly you'd access it using the more useful function:

currentTimer(myHFA)

This gives you the current time, minus the timer value, and thus the number of seconds which
have elapsed since the timer was last reset.  Revisiting the example above, imagine you want
to go forward not for three steps but rather for three seconds, then do a run at the ball.  You
might say:

foo = makeHFA("foo", makeTransition(
    {
    [start] = forward,
    [forward] = function(hfa)    
        if (closeToBall()) then return kick 
        elseif  currentTimer(hfa) > 3 then return run
        else return forward 
        end
    end,
    [kick] = rotate,
    [rotate] = function(hfa) if (ballAhead()) then return forward else return rotate end end,
    [run] = resetTimer,
    [resetTimer] = forward,
    }))



-- TARGETS --

It's often useful to parameterize your behaviors, so that you can create a behavior called
GoTo(X) rather than multiple nearly identical behaviors like GoToTheBall and GoToTheGoal
and GoToTheMidfield and so on.  To do this, we introduce the notion of TARGETS.

A Target is a parameter name (a string) bound to a value (a target, whatever you'd like) 
in a table, such as { ["X"] = TheBall }.  When you create a behavior, you can have a table
of this form passed into your START, STOP, and GO functions.  For example, if you were building
a "goto" behavior, you might have its GO function look like this:

-- GOTO(X)
goto = function(hfa, targets)
    position = positionOf(targets.X)
    turnTo(position)
    walkTowards(position)
end

An HFA can of course also have targets.  It is the job of the transitions to map these targets
to the appropriate names used by the sub-behaviors.  For example, imagine if you had an HFA
called ATTACK which expected two targets called "ball" and "goal".  You have a sub-behavior
called goto which needs the goal target, but it doesn't call it the goal, it calls it "X".
When your transition functions return GoTo, they need to also indicate that the "goal" target
should be provided to goto, renamed to "X".  This is done by not returning goto as
the behavior, but rather returning a table of the form:

{ [0] = goto, ["X"] = "goal" }

This says: goto is the behavior, and provide the "goal" target to goto as a target named "X".

In general this table you'd provide looks like:

{ [0] = the behavior,
        ["behavior's name for first target"] = "hfa's name for target", 
        ["behavior's name for second target"] = "hfa's name for second target", 
        ... }
        
Target names should be strings.  Do not use 0 as a target name, that refers to the behavior.
        
For example, we might have:
        
attack = makeHFA("attack", makeTransition(
    {
    [start] = forward,
    [forward] = function(hfa)    
        if (farFromBall()) then return { [0] = goto, ["X"] = "goal" }
        else return kick
        end,
    [goto] = function(hfa)
        if (closeToBall()) then return forward
        else return { [0] = goto, ["X"] = "goal" }
        end,
    [kick] = { [0] = goto, ["X"] = "goal"}, 
    ...
    }))

... Now you have an "attack" behavior which expects a "goal"  paramter (and perhaps
a "ball" paramter used in some other sub-function not shown), and whenever goto is transitioned
to, the "ball" parameter is passed into goal as the "X" parameter.  Note that you can have
sub-behaviors which take all manner of targets.  For example, forward takes no targets.
You could have another sub-behavior which takes two targets (the ball and the goal, named 
"yo" and "bob" for some reason).  In fact, you could have a sub-behavior which takes THREE
targets, the ball, the goal, and the goal AGAIN, named "no", "way", and "jose".  That's
just fine.

Now, just because an HFA uses a targeted behavior doesn't mean it needs to define targets
itself.  For example, we might provide the targets directly.  For example, imagine that
you had a target called TheGoal stored as a global variable.  You could pass it in directly
as "X" when calling goto like this:

attack = makeHFA("attack", makeTransition(
    {
    [start] = forward,
    [forward] = function(hfa)    
        if (farFromBall()) then return { [0] = goto, ["X"] = TheGoal }
        else return forward
        end,
    [goto] = function(hfa)
        if (closeToBall()) then return forward
        else return { [0] = goto, ["X"] = TheGoal }
        end,
    [kick] = { [0] = goto, ["X"] = TheGoal }, 
    ...
    }))

We call this binding the target to a GROUND VALUE.  Now perhaps attack only needs to be provided
with a "ball" target.  Or if you bound both "goal" and "ball" to ground values when passing them
into sub-behaviors, you wouldn't need either of them in your HFA at all.

Furthermore, your transition functions can pass in different things at different times: you might
have a transition function which provides "goal" as "X", and another one which for some reason
provides "ball" as "X", etc.

So in general, the mapping now looks like this:

{ [0] = the behavior,
        ["behavior's name for first target"] = "hfa's name for target" --OR-- theTargetItself,
        ["behavior's name for second target"] = "hfa's name for second target" --OR-- theTargetItself, 
        ... }

Note that the HFA does not store its targets at all -- it's just up to the transition
functions to map them.  If the targets aren't passed into the HFA by its parent, and you
need them in some sub-behavior, you'll get a mapping error when a transition function tries
to map a target that doesn't exist.

Thus if your HFA is using sub-behaviors which require targets, the transition functions of the
HFA must either bind them to ground values, or they must bind them to targets of their own.
Ultimately, the targets have to be bound to *some* ground value somewhere in the chain of
HFA parents, clear up to pulse().  This is why pulse takes a mapping of target names to targets:

pulse(attack, { ["goal"] = TheGoal, ["ball"] = TheBall })

Of course, if attack doesn't need targets, you can just pass in nil or an empty table.

Additionally, your HFA's transition function may find use of a target helpful.  Perhaps you need
to know the distance to the ball in order to return the right behavior.  In an HFA, the target table
(of the form { ["targetName"] = ground target , ... } ) is stored here:

myHFA.targets

Similarly, the targets, as mapped for the current state, are stored here:

myHFA.behaviorTargets

(You're less likely to use this one)

Thus you could do something like this:

    [forward] = function(hfa)
        ball = hfa.targets.ball
        if (farFrom(ball)) then return{ [0] = goto, ["X"] = TheGoal }
        else return forward
        end,
    
So now we have TWO reasons why an HFA may require targets passed to it:

    1. Because some sub-behavior requires a target and the HFA isn't binding the
       target to a ground value, so the HFA itself needs the target passed in (perhaps
       as a different name)
       
    2. Because the HFA uses the target in a transition function to compute
       the proper transition.
       

KEEP IN MIND that there are two kinds of tables involved here, which look similar but
are different:

    - TARGET TABLES { ["target name"] = ground target, ... }
      Are passed into the START, STOP, and GO methods of behaviors and are also provided
      to the pulse() method.
      
    - MAPPINGS { [0] = behavior, ["target name in behavior"] = "target name in parent HFA"
                                 --OR-- ["target name in behavior"] = ground target, ... }
      Are returned by transition functions to indicate the behavior to transition to and also
      the target mapping to use when passing targets into that behavior.
      


-- ADDITIONAL STUFF TO KEEP IN MIND --

You should be aware of the fact that this library effectively creates directed acyclic
graphs (DAGs) of HFA.  That is, the exact same behavior may be used by different
parent behaviors.  This could have an effect if the behavior maintains some internal
state which is not reset when STOP or START are called.  For example, imagine you had
a behavior called COUNT:

theCount = 0
count = makeBehavior("count", nil, nil, 
    function(behavior, targets) theCount = theCount + 1; print(theCount) end
    )

Now imagine you had two HFAs which both include this behavior among their states.
You're in HFA #1 and it calls count four times, resulting in the numbers 1...4 being
printed to the screen.  Then you're in HFA #2 and it calls count five times.  This
results in the numbers 5...9 being printed to the screen.  This happens because the
same behavior is being used, not multiple copies of it.  If you want multiple copies
of behaviors, you'll need to make them.  Keep this in mind.



... it's always a good sign when the comments are much longer than the code, right?
]]--



-- start
-- This is the start state.  There's no associated behavior,
-- it's just the string "start"
start = "start"


-- translateTargets(targets, mapping)
-- Translates targets in the form of { ["targetName"] = target, ... }
-- Into targets of the form of { ["mappedName"] = target, ... }
-- Using the mapping { [0] = behavior, ["mappedName"] = "targetName", ... }
-- A private internal function used by stopHFA(...) and goHFA(...)
translateTargets = function(targets, mapping)
    mapped = { }
    if (mapping[0] == nil) then
        print("ERROR translateTargets(targets, mapping): mapping does not contain 0 as a key") 
    end
    for mapname, original in pairs(mapping) do
        if (not (mapname == 0)) then
            if (type(original) == "string") then
                if (targets == nil) then
                    print ("ERROR translateTargets(targets, mapping): targets is nil while mapping")
                elseif (targets[original] == nil) then
                    print ("WARNING translateTargets(targets, mapping): targets[original] is nil while mapping")
                else
                    mapped[mapname] = targets[original]
                end
            else
                -- we assume it's a ground target
                mapped[mapname] = original
            end
        end
    end
    return mapped
end

-- startHFA(hfa, targets)
-- Private internal function which is the START function for an HFA.
startHFA = function(hfa, targets)
    hfa.done = false;
    hfa.failed = false;
    hfa.counter = 0;
    -- maybe this is too costly and we should restrict it to the resetTimer function?
    hfa.timer = os.time()
    hfa.goReturnValue = nil;
    hfa.current = start;
end

-- stopHFA(hfa)
-- Private internal function which is the STOP function for an HFA.
stopHFA = function(hfa, targets)
	hfa.targets = nil
    if (hfa.current == nil) then
    	print("WARNING (stopHFA) current is nil")
    elseif (not (hfa.current == start)) then
    	if (not (hfa.current.stop == nil)) then
        	hfa.current.stop(hfa.current, hfa.behaviorTargets)
        end
    	hfa.current.parent = nil
    end
end

-- goHFA(hfa)
-- Private internal function which is the GO function for an HFA.
goHFA = function(hfa, targets)
    hfa.targets = targets

    -- DETERMINE TRANSITION
    local newBehavior = nil
    
    if (not (hfa.transition == nil)) then
        newBehavior = hfa.transition(hfa)
    end
    if (newBehavior == nil) then
        newBehavior = hfa.goReturnValue
    end
    hfa.goReturnValue = nil
    
    -- EXTRACT TARGETS
    -- this is the previous subset, we use it in calling stop() if necessary
    local oldBehaviorTargets = hfa.behaviorTargets
    -- figure out the new subset.  We test for target lists based on whether
    -- the table provided has 0 as a key
    if (not (newBehavior == nil) and not (newBehavior[0] == nil)) then
        -- translate using newBehavior as a mpaping, ignoring [0], which is the "real" newbehavior
        hfa.behaviorTargets = translateTargets(targets, newBehavior)
        newBehavior = newBehavior[0]
    else
        hfa.behaviorTargets = nil
    end
        
    -- PERFORM TRANSITION
    if (not (newBehavior == nil)) then
        if (not (newBehavior == hfa.current)) then
            if (hfa.current == nil)  then
    			print("WARNING (stopHFA) current is nil")
    		elseif (not (hfa.current == start)) then
				if (not (hfa.current.stop == nil)) then
                    hfa.current.stop(hfa.current, oldBehaviorTargets)
                 end
    			hfa.current.parent = nil
            end
            newBehavior.parent = hfa
            if (not (newBehavior.start == nil)) then
                newBehavior.start(newBehavior, hfa.behaviorTargets)
            end
            hfa.current = newBehavior
            hfa.done = false
            hfa.failed = false
        end
    else
        print("WARNING (goHFA): nil new behavior")
    end
            
    -- EXECUTE
    if (hfa.current == nil) then
        print("WARNING (goHFA): nil current behavior")
    elseif (hfa.current == start) then
    	print("WARNING (goHFA): start current behavior")
    elseif (not (hfa.current.go == nil)) then
        hfa.goReturnValue = hfa.current.go(hfa.current, hfa.behaviorTargets)
    end
end


-- makeTransition(transitions)
-- transitions is a dictionary whose keys are
-- behaviors (states) and whose values are either OTHER behaviors
-- or transition functions of the form foo(hfa) which, when called,
-- return what the next state should be.  If the value is a behavior (state),
-- then the HFA will ALWAYS transition to this second state when it is currently in
-- the state associated with key.  If the value is a transition function, then the
-- HFA will call the transition function and transition to the state indicated.
makeTransition = function(transitions)
    return function(hfa)
        local transition = nil
        print("hfa current:" .. tostring(hfa.current.name))
        if (hfa.current == nil) then
        	print("WARNING (makeTransition): current is nil")
        else
            transition = transitions[hfa.current]
        end
        if (type(transition) == "function") then
            return transition(hfa)
        else
            return transition
        end
    end
end

-- makebehavior(name, start, stop, go)
-- Creates a behavior with the given name and start/stop/go functions.  Any
-- of these functions can be nil.
makeBehavior = function(name, start, stop, go)
    return { ["name"] = name, ["start"] = start, ["stop"] = stop, 
    		 ["go"] = go, ["parent"] = nil, ["pulsed"] = false }
end

-- makeHFA(name, transition)
-- Creates an HFA with the given name and transition function.
-- Though the transition function can be nil, it's almost certainlly not appropriate to do so.
makeHFA = function(name, transition)
    return { ["name"] = name, ["start"] = startHFA, ["stop"] = stopHFA, ["go"] = goHFA, 
             ["transition"] = transition, ["pulsed"] = false,
             ["parent"] = nil, ["goReturnValue"] = nil, ["counter"] = 0, ["timer"] = 0, 
             ["done"] = false, ["failed"] = false, ["current"] = start,
             ["propagateFlags"] = false, ["targets"] = nil, ["behaviorTargets"] = nil }
end

-- makeWrapper(name, wrappedBehavior)
-- Creates a wrapper HFA for the given behavior, which works exactly like the
-- behavior does.  This allows you to have the same behavior appear as multiple
-- states in a parent HFA.
makeWrapper = function(name, wrappedBehavior)
  return makeHFA(name, 
                 function(hfa)
                   return wrappedBehavior 
                 end)
end
    

-- Pulses the behavior.  This is the top-level stepping procedure for your HFA.
pulse = function(behavior, targets)
    if (not behavior.pulsed) then
        behavior.pulsed = true
        if (not (behavior.start == nil)) then
            behavior.start(behavior, targets)
        end
    end
    if (not (behavior.go == nil)) then
        behavior.go(behavior, targets)
    end
end
        

-- Resets a behavior so that next time it is pulsed, it will call start() again.
reset = function(behavior, targets)
    if (behavior.pulsed) then
        if (not (behavior.stop == nil)) then
            behavior.stop(behavior, targets)
        end
        behavior.pulsed = false
    end
end


-- UTILITY BEHAVIORS --

-- bumpCounter: increments the HFA's counter by 1
bumpCounter = makeBehavior("bumpCounter", 
    function(behavior, targets) 
        if (not (behavior == nil) and not (behavior.parent == nil)) then 
            behavior.parent.counter = behavior.parent.counter + 1
        end
    end, nil, nil)

-- zeroCounter: sets the HFA's counter to 0
resetCounter = makeBehavior("resetCounter",
    function(behavior, targets) 
        if (not (behavior == nil) and not (behavior.parent == nil)) then 
            behavior.parent.counter = 0
        end
    end, nil, nil)
    
-- currentCounter(hfa) returns the HFA's current counter value.  This is a 
--                     helpful utility function for making transition functions.
currentCounter = function(hfa) return hfa.counter end

-- resetTimer: resets the HFA's current timer value.  This is a helpful utility
--                   function for making transition functions.
resetTimer = makeBehavior("resetTimer",
    function(behavior, targets)
        if (not (behavior == nil) and not (behavior.parent == nil)) then
            behavior.parent.timer = os.time()
        end
    end, nil, nil)

-- currentTimer(hfa) returns the difference between the current time and the
--                   HFA's current timer value.  This is a helpful utility
--                   function for making transition functions.
currentTimer = function(hfa) return os.time() - hfa.timer end

-- setFlag(hfa, flag).  Internal private function used by various flag behaviors
--                      to set a flag in an HFA, potentially recursively if
--                      propagation is turned on.
setFlag = function(hfa, flag)
    if (not (hfa.parent == nil)) then
        hfa.parent[flag] = true
        if (hfa.parent.propagateFlags == true) then
            setFlag(hfa.parent, flag)
        end
    end
end

-- done: sets the "done" flag in the HFA's parent, and transitions to "start"
done = makeBehavior("done", nil, nil,
    function(behavior, targets) 
    print(behavior.name)
    print(behavior.parent.name)
	if (not (behavior == nil) and not (behavior.parent == nil)) then
		behavior.parent.current = start
        setFlag(behavior.parent, "done")
        behavior.parent = nil
    end
 end)

-- sayDone: sets the "done" flag in the HFA's parent
sayDone = makeBehavior("sayDone", 
    function(behavior, targets)
        if (not (behavior == nil) and not (behavior.parent == nil)) then
            setFlag(behavior.parent, "done")
        end
    end, nil, nil)
    
-- isDone(hfa)	returns the current done flag in the HFA
isDone = function(hfa) return hfa.done end

-- isFailed(hfa)	returns the current failed flag in the HFA
isFailed = function(hfa) return hfa.failed end
    
-- failed: sets the "failed" flag in the HFA's parent, and transitions to "start"
failed = makeBehavior("failed", nil, nil,
    function(behavior, targets) 
        if (not (behavior == nil) and not (behavior.parent == nil)) then
            behavior.current = start
            setFlag(behavior.parent, "failed")
            behavior.parent = nil
        end
    end)

-- sayFailed: sets the "failed" flag in the HFA's parent
sayFailed = makeBehavior("sayFailed", 
    function(behavior, targets)
        if (not (behavior == nil) and not (behavior.parent == nil)) then
            setFlag(behavior.parent, "failed")
        end
    end, nil, nil)



-- END HFA.LUA


printAStart = function(behavior, targets)
	print("start a")
end
printAStop = function(behavior, targets)
	print("stop a")
end
printAGo = function(behavior, targets)
	print("go a")
end
printA = makeBehavior("printA", printAStart, printAStop, printAGo);

printBStart = function(behavior, targets)
	print("start b")
end
printBStop = function(behavior, targets)
end
printBGo = function(behavior, targets)
--	print("go b " .. targets["X"])
end
printB= makeBehavior("printB", printBStart, printBStop, printBGo);

foo = makeHFA("foo", makeTransition(
        {
		[start] = printA,
		[printA] = printB, 
		[printB] = function() print("counter is " .. tostring(foo.counter)); return resetTimer end,
		[resetTimer] = function() if(currentTimer(foo) > 5) then return done else return printA end end;
	}))
bar = makeHFA("bar", makeTransition(
	{
		[start] = foo,
		[foo] = function() 
			print("coming out of foo? " .. tostring(bar.counter)); 
			if(bar.done) then 
				print("yes") 
				return bumpCounter
			else 
				print("no") 
				return foo 
			end 
		end,
		[bumpCounter] = done
	}))

number = 1;
while 1 do
	print("i am pulsing");
	number = number+1
	pulse(bar);
	
end

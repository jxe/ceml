Introducing CEML
================

CEML is the world's first programming language custom-built for bringing people together.

Short scripts define the structure for live coordinated events among people with different roles and across locations.

All assignments and reassignments given in Groundcrew are CEML programs that are submitted via our API and executed on the server.  Scripts can result in a text message, IM, twitter, and mobile application-based coordination.

A sample program
----------------

    "some quiet time"
    takes 10m
    offers quiet observation connection peace
    gather many agents, 1 landmark

    tell agents:
        at |landmark|, find a place to sit w hands on left leg
        in silence, listen to noises in the park
        after |duration|, cough gently and leave one at a time

or the slightly more complex rendezvous:

    "a high five"
    takes 2m
    offers connection inclusion
    gather 1 mobile_agent, 1 stationary_agent, 1 streetcorner

    ask stationary_agent re clothing: What are you wearing (so the other person can recognize you)?

    tell stationary_agent:
        mill around at |streetcorner|
        a stranger will approach you and give you a high five
        when that happens nod and run in the direction they came from
        find some trash and clean it up

    tell mobile_agent:
        go to |streetcorner| and
        find someone wearing |stationary_agent.clothing|
        give them a high five
        nod, and keep walking around the corner

There are more examples in this repo.

Other resources
---------------

There is a TextMate bundle which does syntax highlighting for CEML.  Someone will make a vim mode soon.  I am sure of it.

Reference - Commands
--------------------

CEML has a small number of keywords at this point:  `gather`, `tell`, `ask`, and `assign` are the main four.  `nab` is a variant of `gather`. `takes` and `offers` have a supporting role to provide metadata.

### ask [role] re [varname]: [question]

Used to indicate that the information for the varname can be obtained by asking someone in the role/group the question provided.

### tell [role]: [assignment]

Says to give the assignment to the people who match the role.  Note that the assignment may have variables embedded within it, in which case the server will attempt to get values by asking questions, etc, before sending these assignments.

### gather rolespec1, rolespec2, ... [block]

Declares a set of roles which need to be filled to run this script.

### offers [tags]

Helps the user or the system pick which agents to involve, based on what they're up for.

### takes [duration] [optional skill tags]

Also helps the user or the system pick which agents to involve, based on their skills and/or available time.

Reference - Syntax
------------------

The syntax is simple and inherits from tcl and ruby.  Every line starts with a command keyword, some arguments, and possibly a string after a colon.  Like RFC822 headers, a terminal string parameter can fall either directly after a colon or on a series of indented line.

Copyright
------------------

Copyright (c) 2010 Citizen Logistics, Inc. See LICENSE for details.

This software is licensed under the AGPL, the Affero General Public License 3.0.

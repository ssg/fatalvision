
 FatalVision
 ~~~~~~~~~~~

 Copyright (c) 1993,..,1998 Sedat Kapanoglu & Meric Sentunali


WHAT IS FATALVISION
~~~~~~~~~~~~~~~~~~~
FatalVision is a set of Borland Pascal libraries. A set that has been
built in years, with hell a lot of effort. A set that developed its own
authors while it's being developed. A set that gave us experience. A set
that made us men.

HISTORY
~~~~~~~
There's a lot to tell here which will go beyond the purpose of this
document, so I will keep it short. It was May 1993 and I (SSG) was
workin' on graphical user interfaces. Suat Esen (Wiseman) made an
offer to develop a commercial program. I'd be the GUI coder. I accepted
and we began. A month later, another coder Meric Sentunali (FatalicA)
had started to code a GUI too. He introduced some new techniques which
we couldn't stand without adapting our sources to his. So we united.
The satisfiying completion of GUI code took about 6 months. But we
didn't stop there. We had no other job to do so we coded, and coded
whatever came to our minds. At the end of 1994, FatalicA and Wiseman
stopped the coding of the GUI. It was almost finished. But I kept
retouching it until end of 97. I had released many utilities using that
library.

IMPORTANCE
~~~~~~~~~~
FatalVision is NOT a technical miracle. It's not even throughly
designed. (hey, is it ever designed?) It can never be used by other
people since the lack of documentation and terminology conflicts. But,
it served us well. I am sure that it was the most advanced user
interface library ever created for specific applications for DOS in its
time. But I'm gonna give no fuck to prove it or whatever.

So what makes FatalVision special? It's special because WE DID IT. It's
special because I owe most of the things I have now to that project. If
someone calls me a "coder" now, it's because of that. I can never finish
listing the things that project gave me here. So just know it's special.

TECH DETAILS
~~~~~~~~~~~~
FatalVision is not a complete replacement library. In fact, it needs
TurboVision and BGI interface to work. Why needs TurboVision? Because 
it's bugfree and why write everything from scratch? Why needs BGI? 
The same reason.

In the aspect of the performance, FatalVision is good. Because its
development mostly done on a 386SX/25 2meg RAM and a 386DX/40 2meg RAM..

The bitmap blit engine has been completely rewritten to achive maximum
gfx performance. Other BGI routines were almost the fastest so we 
chose to trust Borland.

The GUI logic is almost identical to TurboVision. There are TView,
TGroup, TWindow objects of FatalVision. (So you can guess why the both
names end with "Vision")

Some libraries are independent of the GUI. (Such as XBuf, XIO etc).. The
ones that are useless without GUI, are marked in the 00index.txt file of
"src\" subdirectory.

If you want to see something done with this GUI, download the off line
mail reader "Wolverine" from any Simtel mirror. (http://www.simtel.net)

WHY GIVE AWAY THE CODE?
~~~~~~~~~~~~~~~~~~~~~~~
Because FatalVision is dead. It's outdated. I'm not developing it
anymore. Why they show T-Rex in museums? That's why.

DOCUMENTATION
~~~~~~~~~~~~~
Aha... You are stuck there...

LICENSE
~~~~~~~
FatalVision is public domain. Make commercial apps with it. Make money with
it. Copy it. Pirate it. Don't greet us in the apps you did with it. 

CONTACT
~~~~~~~
If you want to make some comments:

SSG:
   ssg@sourtimes.org

FatalicA:
   fatalica@sourtimes.org

The aRtEffECt homepage:
   http://www.arteffect.org


26th Mar 97

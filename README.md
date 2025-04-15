FatalVision
===========

What is FatalVision?
-------------------
FatalVision is a set of Borland Pascal libraries. A set that has been
built in years, with hell a lot of effort. A set that developed its own
authors while it's being developed. A set that gave us experience. A set
that made us men.

Screenshots
-----------
These are the tools I wrote using FatalVision, all written by me:

Baston file manager, 1st place winner of Altin Disket 94 Programming Competition in DOS Category:

![baston](https://user-images.githubusercontent.com/241217/159136746-e05f6e95-eaca-4dc3-9dcd-ddd7aa2a0478.png)

Context-sensitive hypertext help of Baston:

![baston help system screenshot](https://user-images.githubusercontent.com/241217/159136763-e8ed9e4d-1e0b-4727-8c07-2ec82a890d9a.png)

[Wolverine](https://github.com/ssg/wolverine) off-line mail reader for FidoNet-style networks:

![wolverine 2.30 screenshot](https://user-images.githubusercontent.com/241217/159136787-e1a8cf26-6d2e-43b1-a653-081d3dee8bb5.png)

[Wolverine](https://github.com/ssg/wolverine) context-sensitive hypertext help:

![wolverine help](https://user-images.githubusercontent.com/241217/159136783-52c32bc3-4d36-485b-9a35-da7b038f4405.png)

[GenAv](https://github.com/ssg/genav) antivirus:

![genav screenshot](https://user-images.githubusercontent.com/241217/159136911-746a054e-38bc-4a9b-b76d-e660ce90581a.png)

Gendis patient management software for dentists:

![gendis screenshot](https://github.com/user-attachments/assets/5230289a-1c9c-421b-8e13-6534923d1d2f)

History
-------
There's a lot to tell here which will go beyond the purpose of this
document, so I will keep it short. It was May 1993 and I (SSG) was
working on graphical user interfaces. Suat Esen (Wiseman) made an
offer to develop a commercial program; I'd be the GUI coder. I accepted
and we began. A month later, another coder, Meric Sentunali (FatalicA)
had started to code a GUI too. He introduced some new techniques which
we couldn't stand without adapting our sources to his. So we united.
Getting to a usable GUI took about 6 months. But we
didn't stop there. We had no other job to do, so we coded, and coded
whatever came to our mind. At the end of 1994, FatalicA and Wiseman
stopped the coding the GUI. It was almost finished. But I kept
working on it until end of 97. I had released many utilities using that
library.

Importance
----------
FatalVision was NOT a technical miracle. It wasn't even thoroughly
designed. (Hey, was it ever designed?) It could never be used by other
people since the lack of documentation and conflicting terminology. But,
it served us well. I think it was one of the most advanced user
interface libraries ever created for DOS applications in its
time.

So what makes FatalVision special? It's special because WE MADE IT. It's
special because I owe my foundational knowledge of programming to 
that project. If someone calls me a "coder" now, it's because of that. 
I can never finish listing the things that project gave me here. 
So just know it's special.

Tech Details
------------
FatalVision is not a complete replacement library. In fact, it needs
TurboVision and BGI interface to work. Why does it need TurboVision? Because 
it's bug-free and why write everything from scratch? Why does it need BGI? 
The same reason.

In the aspect of the performance, FatalVision is good. Because its
development was mostly done on a 386SX/25 and a 386DX/40 both with 2MB RAM.

The bitmap blit engine has been completely rewritten to achive maximum
performance. Other BGI routines were already fast so we chose to trust Borland.

The GUI API is quite similar to TurboVision. There are TView,
TGroup, TWindow objects in FatalVision too. (So you can guess why the both
names end with "Vision")

Some libraries like XBuf, XIO are lower-level than GUI and can be (and were) used in
non-GUI applications. The ones that are useless without a GUI are marked in 
the 00index.txt file of "src\" subdirectory.

If you want to see something done with this GUI, check out my off-line
FidoNet mail reader [Wolverine](https://github.com/ssg/wolverine).

Why Give Away The Code?
-----------------------
Because it's dead. It's outdated. I'm not developing it
anymore. Why do they show T-Rex in museums? That's why.

Documentation?
-------------
Aha... You are stuck there...

License
-------
FatalVision is public domain. Make commercial apps with it. Make money with
it. Copy it. Pirate it. Don't greet us in the apps you did with it. 

Copyright (c) 1993,..,1998 Sedat Kapanoglu & Meric Sentunali

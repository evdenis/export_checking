# Description
The tool allows to find EXPORT\_SYMBOL functions marked as \_\_init,
\_\_exit, inline or static.

# Usage
To check particular file:

    ./check_export.pl <options> <file>
    Options:
       --init|-i - check for "__init"
       --exit|-e - check for "__exit"
       --inline|-n - check for "inline"
       --static|-s - check for "static"

To check the whole kernel:

    ./check_export.sh <options> <kernel dir> <output>
    Options:
        i - __init
        e - __exit
        n - inline
        s - static

# Found bugs
* [e4eda8e0](https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=e4eda8e0654c19cd7e3d143b051f3d5c213f0b43)
* [19d8cedd](https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=19d8ceddda8b3a806a0960106ae6aa4dcc21df3b)

# False positives

    #ifdef CONFIG_SOMETHING
    
    static int
    func( void )
    {
    }
    
    #else

    int
    func( void )
    {
    }
    EXPORT_SYMBOL(func)

    #endif

In this case tool will report that funcion `func` is exported and marked as
static.

## Examples of false positives
* static int \_\_init arch\_register\_cpu( int num )  
linux/arch/ia64/kernel/topology.c

* static int \_\_init arch\_register\_cpu( int num )  
linux/arch/x86/kernel/topology.c
    
# Timings

AMD Phenom(tm) II N850 Triple-Core Processor

$ ./test.sh  

\+ ./check\_export.sh i ../linux init\_list  
real	5m44.249s  
user	16m1.569s  
sys	0m24.332s  

\+ ./check\_export.sh e ../linux exit\_list  
real	5m42.859s  
user	16m7.166s  
sys	0m23.709s  

\+ ./check\_export.sh n ../linux inline\_list  
real	5m40.633s  
user	16m2.811s  
sys	0m23.564s  

\+ ./check\_export.sh s ../linux static\_list  
real	5m40.425s  
user	16m4.500s  
sys	0m23.459s  

\+ ./check\_export.sh ie ../linux init\_exit\_list  
real	6m53.704s  
user	17m15.901s  
sys	0m23.521s  

\+ ./check\_export.sh ien ../linux init\_exit\_inline\_list  
real	7m14.452s  
user	15m34.238s  
sys	0m23.545s  

\+ ./check\_export.sh iens ../linux init\_exit\_inline\_static\_list  
real	4m51.633s  
user	13m36.852s  
sys	0m23.834s  

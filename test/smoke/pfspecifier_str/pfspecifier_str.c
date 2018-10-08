#include <stdio.h>
#include <omp.h>

int f(int a)
{
  return a/10;
}

int main()
{
    printf ("String on   host: %s\n", "12345_ABCDEFGabcdegf?!");
#pragma omp target
  {
    char *str = "12345_ABCDEFGabcdegf?!";
    char *str_alt = "67890_XYZxyz?!";
    char *fmt = "String on device: %s\n";
    printf ("String on device: %s\n", "12345_ABCDEFGabcdegf?!");
    printf ("String on device: %s\n", str);
    printf (fmt, str);
// Choose string to print
    printf (fmt, f(1) ? str_alt : str);
    printf (fmt, f(10) ? str_alt : str);
// Choose string format size using variable, string will be right aligned
    printf ("String on device: %*s\n", f(220), f(10) ? str_alt : str);
// Choose maximium string format size using variable
// Currently doesn't work on Nvidia
//    printf ("String on device: %.*s\n", f(70), f(1) ? str_alt : str);
  }

  return 0;
}
